# frozen_string_literal: true

# Presentation layer between chat.messages and the chatbox view.
#
# Accepts an ActiveRecord::Relation or Array of Message records and groups
# them into a flat list of renderable Entry value objects.  Consecutive
# "thinking" messages (system / tool_call / tool_result / thinking_text) are
# merged into a single ThinkingEntry so the view never needs to re-implement
# that grouping logic (previously done in JavaScript).
#
# Usage:
#   presenter = MessagePresenter.new(@chat.messages)
#   presenter.entries  # => [ThinkingEntry, RegularEntry, ChoiceEntry, ...]
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

  # A consecutive run of thinking-kind messages collapsed into one widget.
  # `actions` is an Array of ActionItem describing each step.
  ThinkingEntry = Data.define(:actions, :lead_message_id)

  # A single visible chat bubble (user or assistant text).
  RegularEntry = Data.define(:message)

  # An assistant message rendered as tappable choice buttons.
  ChoiceEntry = Data.define(:message, :payload)

  # One row inside a ThinkingEntry.
  ActionItem = Data.define(:status_label, :detail_label, :thinking_text, :done)

  def initialize(messages)
    @messages = messages
  end

  def entries
    result = []
    pending_thinking = []

    Array(@messages).each do |msg|
      if thinking_message?(msg)
        pending_thinking << msg
      else
        flush_thinking(pending_thinking, result)
        pending_thinking = []

        cp = msg.choice_payload
        if cp
          result << ChoiceEntry.new(message: msg, payload: cp)
        else
          result << RegularEntry.new(message: msg)
        end
      end
    end

    flush_thinking(pending_thinking, result)
    result
  end

  private

  def thinking_message?(msg)
    return false if msg.role.blank?

    msg.thinking_message?
  end

  def flush_thinking(msgs, result)
    return if msgs.empty?

    actions = msgs.map { |msg| build_action_item(msg) }
    result << ThinkingEntry.new(actions:, lead_message_id: msgs.first.id)
  end

  def build_action_item(msg)
    if msg.tool_call?
      ActionItem.new(
        status_label: "アクションを実行中",
        detail_label: msg.tool_calls.map { |tc| tool_label(tc.name) }.join(", "),
        thinking_text: nil,
        done: false
      )
    elsif msg.tool_result?
      name = msg.parent_tool_call&.name.to_s
      summary = TOOL_RESULT_SUMMARIES[name] || "#{tool_label(name)}を実行しました"
      ActionItem.new(
        status_label: "アクション完了",
        detail_label: summary,
        thinking_text: nil,
        done: true
      )
    elsif msg.role.to_s == "system"
      ActionItem.new(
        status_label: "システム設定",
        detail_label: nil,
        thinking_text: nil,
        done: true
      )
    else
      ActionItem.new(
        status_label: "考え中",
        detail_label: nil,
        thinking_text: msg.thinking_text.presence,
        done: false
      )
    end
  end

  def tool_label(tool_name)
    name = tool_name.to_s
    TOOL_NAME_LABELS[name] || name.split("--").last&.titleize || name
  end
end
