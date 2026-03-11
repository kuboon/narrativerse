# frozen_string_literal: true

# Presentation layer between chat.messages and the chatbox view.
#
# Accepts an ActiveRecord::Relation or Array of Message records and returns
# a flat list of renderable Entry value objects.
#
# Thinking-related messages are represented as independent entries:
# - ActionItem for system / tool_call / tool_result messages
# - ThinkingEntry for assistant thinking_text messages
#
# Usage:
#   presenter = MessagePresenter.new(@chat.messages)
#   presenter.entries  # => [ActionItem, ThinkingEntry, RegularEntry, ChoiceEntry, ...]
class MessagePresenter
  TOOL_NAME_LABELS = {
    "plot_chatbot--add_plot_element"    => "要素の追加",
    "plot_chatbot--update_plot_element" => "要素の更新",
    "plot_chatbot--add_scene"           => "シーンの追加",
    "plot_chatbot--update_scene"        => "シーンの更新",
    "plot_chatbot--search_elements"     => "プロット外の要素を検索",
    "plot_chatbot--list_plot_elements"  => "プロット内の全要素を確認",
    "plot_chatbot--list_scenes"         => "全てのシーンを確認",
    "plot_chatbot--present_choices"     => "選択肢を提示"
  }.freeze

  TOOL_RESULT_SUMMARIES = {
    "plot_chatbot--add_plot_element"    => "要素を追加しました",
    "plot_chatbot--update_plot_element" => "要素を更新しました",
    "plot_chatbot--add_scene"           => "シーンを追加しました",
    "plot_chatbot--update_scene"        => "シーンを更新しました",
    "plot_chatbot--search_elements"     => "要素を検索しました",
    "plot_chatbot--list_plot_elements"  => "プロット内の要素を確認しました",
    "plot_chatbot--list_scenes"         => "シーン一覧を確認しました",
    "plot_chatbot--present_choices"     => "選択肢を提示しました"
  }.freeze

  # A single assistant thinking text displayed as a collapsible block.
  ThinkingEntry = Data.define(:status_label, :thinking_text, :lead_message_id, :done)

  # A single visible chat bubble (user or assistant text).
  RegularEntry = Data.define(:message)

  # An assistant message rendered as tappable choice buttons.
  ChoiceEntry = Data.define(:message, :payload)

  # A single system/tool action displayed as a collapsible block.
  ActionItem = Data.define(:status_label, :detail_label, :execution_text, :lead_message_id, :done)

  def initialize(messages)
    @messages = messages
  end

  def entries
    messages = Array(@messages)
    @completed_tool_call_ids = messages
      .select { |m| m.role.present? && m.tool_result? }
      .filter_map { |m| m.parent_tool_call&.message_id }
      .to_set

    result = []
    messages.each do |msg|
      if thinking_message?(msg)
        entry = build_thinking_related_entry(msg)
        result << entry if entry
      else
        cp = msg.choice_payload
        if cp
          result << ChoiceEntry.new(message: msg, payload: cp)
        else
          result << RegularEntry.new(message: msg)
        end
      end
    end

    result
  end

  private

  def thinking_message?(msg)
    return false if msg.role.blank?

    msg.thinking_message?
  end

  def build_thinking_related_entry(msg)
    return build_action_item(msg) if action_message?(msg)

    ThinkingEntry.new(
      status_label: "考え中",
      thinking_text: msg.thinking_text.presence || msg.content.presence,
      lead_message_id: msg.id,
      done: false
    )
  end

  def action_message?(msg)
    msg.tool_call? || msg.tool_result? || msg.role.to_s == "system"
  end

  def build_action_item(msg)
    if msg.tool_call?
      return if choice_tool_call?(msg)
      return if @completed_tool_call_ids&.include?(msg.id)

      ActionItem.new(
        status_label: "アクションを実行中",
        detail_label: msg.tool_calls.map { |tc| tool_label(tc.name) }.join(", "),
        execution_text: format_tool_call_execution(msg),
        lead_message_id: msg.id,
        done: false
      )
    elsif msg.tool_result?
      name = msg.parent_tool_call&.name.to_s
      summary = TOOL_RESULT_SUMMARIES[name] || "#{tool_label(name)}を実行しました"
      ActionItem.new(
        status_label: "アクション完了",
        detail_label: summary,
        execution_text: format_tool_result_execution(msg.content),
        lead_message_id: msg.id,
        done: true
      )
    end
  end

  def choice_tool_call?(msg)
    msg.tool_calls.all? { |tc| tc.name.to_s.end_with?("--#{Message::CHOICE_TOOL_NAME}") || tc.name.to_s == Message::CHOICE_TOOL_NAME }
  end

  def format_tool_call_execution(msg)
    lines = msg.tool_calls.map do |tool_call|
      payload = format_json_payload(tool_call.arguments)
      label = tool_label(tool_call.name)
      payload.present? ? "#{label}\n#{payload}" : label
    end

    lines.join("\n\n").presence
  end

  def format_tool_result_execution(raw_content)
    return if raw_content.blank?

    parsed = JSON.parse(raw_content)
    JSON.pretty_generate(parsed)
  rescue JSON::ParserError
    raw_content
  end

  def format_json_payload(payload)
    return if payload.blank?

    JSON.pretty_generate(payload.as_json)
  rescue JSON::GeneratorError, TypeError
    payload.to_s
  end

  def tool_label(tool_name)
    name = tool_name.to_s
    TOOL_NAME_LABELS[name] || name.split("--").last&.titleize || name
  end
end
