# frozen_string_literal: true

# Presentation layer between chat.messages and the chatbox view.
# Encapsulates display logic so that views stay free of conditionals.
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

  # Summary shown in the tool_result row (e.g. "シーンを追加しました")
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

  attr_reader :message

  def initialize(message)
    @message = message
  end

  # -- Kind -----------------------------------------------------------------

  def kind
    if message.thinking_message?
      :thinking
    elsif message.choice_payload
      :choice
    else
      :regular
    end
  end

  def thinking? = kind == :thinking
  def choice?   = kind == :choice
  def regular?  = kind == :regular

  # -- Speaker / placement --------------------------------------------------

  def speaker_name
    message.role == "user" ? "あなた" : "AI"
  end

  def placement
    message.role == "user" ? "chat-end" : "chat-start"
  end

  def bubble_color
    message.role == "user" ? "" : "chat-bubble-neutral"
  end

  # -- Thinking row ---------------------------------------------------------

  # Short status label shown in the <summary> bar.
  def status_label
    if message.tool_call?
      "アクションを実行中"
    elsif message.tool_result?
      "アクション完了"
    elsif message.role.to_s == "system"
      "システム設定"
    else
      "考え中"
    end
  end

  # For tool_call rows: comma-separated human-readable tool names.
  def tool_names_label
    return unless message.tool_call?

    message.tool_calls.map { |tc| tool_label(tc.name) }.join(", ")
  end

  # For tool_result rows: human-readable completion summary, e.g. "シーンを追加しました".
  # Falls back to a generic "完了しました" when the tool name is unknown.
  def tool_result_summary
    return unless message.tool_result?

    name = message.parent_tool_call&.name.to_s
    TOOL_RESULT_SUMMARIES[name] || "#{tool_label(name)}を実行しました"
  end

  private

  def tool_label(tool_name)
    name = tool_name.to_s
    TOOL_NAME_LABELS[name] || name.split("--").last&.titleize || name
  end
end
