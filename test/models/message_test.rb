require "test_helper"

class MessageTest < ActiveSupport::TestCase
  extend Minitest::Spec::DSL

  it "parses choice payload from present_choices tool result" do
    user = create(:user)
    chat = create(:chat, user:)

    tool_call_message = chat.messages.create!(role: "assistant", content: "")
    tool_call = tool_call_message.tool_calls.create!(
      name: "present_choices",
      tool_call_id: "tool-call-1",
      arguments: { prompt: "選んでください" }
    )

    message = chat.messages.create!(
      role: "tool",
      tool_call_id: tool_call.id,
      content: { type: "choices", prompt: "選んでください", choices: [ "A", "B", "A" ] }.to_json
    )

    payload = message.choice_payload

    _(message.choice_message?).must_equal true
    _(message.thinking_message?).must_equal false
    _(payload["prompt"]).must_equal "選んでください"
    _(payload["choices"]).must_equal [ "A", "B" ]
  end

  it "parses choice payload from namespaced present_choices tool result" do
    user = create(:user)
    chat = create(:chat, user:)

    tool_call_message = chat.messages.create!(role: "assistant", content: "")
    tool_call = tool_call_message.tool_calls.create!(
      name: "plot_chatbot--present_choices",
      tool_call_id: "tool-call-namespace-1",
      arguments: { prompt: "選んでください" }
    )

    message = chat.messages.create!(
      role: "tool",
      tool_call_id: tool_call.id,
      content: { type: "choices", prompt: "選んでください", choices: [ "A", "B" ] }.to_json
    )

    payload = message.choice_payload

    _(message.choice_message?).must_equal true
    _(message.thinking_message?).must_equal false
    _(payload["prompt"]).must_equal "選んでください"
    _(payload["choices"]).must_equal [ "A", "B" ]
  end

  it "marks system and tool-call messages as thinking" do
    user = create(:user)
    chat = create(:chat, user:)

    system_message = chat.messages.create!(role: "system", content: "system prompt")
    _(system_message.thinking_message?).must_equal true

    tool_call_message = chat.messages.create!(role: "assistant", content: "")
    tool_call_message.tool_calls.create!(
      name: "search_elements",
      tool_call_id: "tool-call-2",
      arguments: { query: "探偵" }
    )

    _(tool_call_message.reload.thinking_message?).must_equal true

    thinking_text_message = chat.messages.create!(role: "assistant", content: "Final answer", thinking_text: "Reasoning...")
    _(thinking_text_message.thinking_message?).must_equal true
  end

  it "parses choice payload from assistant json" do
    user = create(:user)
    chat = create(:chat, user:)

    message = chat.messages.create!(
      role: "assistant",
      content: {
        type: "choices",
        prompt: "何から始めましょうか？",
        choices: [ "A", "B", "A", "" ]
      }.to_json
    )

    payload = message.choice_payload

    _(message.choice_message?).must_equal true
    _(message.thinking_message?).must_equal false
    _(payload["prompt"]).must_equal "何から始めましょうか？"
    _(payload["choices"]).must_equal [ "A", "B" ]
  end

  it "parses choice payload from markdown code fence" do
    user = create(:user)
    chat = create(:chat, user:)

    message = chat.messages.create!(
      role: "assistant",
      content: <<~TEXT
        提案します。
        ```json
        {"type":"choices","prompt":"追加したい要素を選んでください。","choices":["1) 主人公","2) 仲間"]}
        ```
      TEXT
    )

    payload = message.choice_payload

    _(message.choice_message?).must_equal true
    _(message.thinking_message?).must_equal false
    _(payload["prompt"]).must_equal "追加したい要素を選んでください。"
    _(payload["choices"]).must_equal [ "1) 主人公", "2) 仲間" ]
  end

  it "parses choice payload from embedded json in text" do
    user = create(:user)
    chat = create(:chat, user:)

    message = chat.messages.create!(
      role: "assistant",
      content: "以下を表示します: {\"type\":\"choices\",\"prompt\":\"選んでください\",\"choices\":[\"A\",\"B\"]}"
    )

    payload = message.choice_payload

    _(message.choice_message?).must_equal true
    _(message.thinking_message?).must_equal false
    _(payload["prompt"]).must_equal "選んでください"
    _(payload["choices"]).must_equal [ "A", "B" ]
  end

  it "parses choice payload from truncated choices json" do
    user = create(:user)
    chat = create(:chat, user:)

    message = chat.messages.create!(
      role: "assistant",
      content: <<~TEXT.strip
        {"type":"choices","prompt":"次に追加したい要素を選んでください。番号で回答してください。","choices":["1) 仲間を追加する: 放浪の薬草師ミナ","2) 敵対者を追加する: 王都の陰謀を操る影の宰相","3) 舞台を追加する: 砂漠のオアシス都市ウィルダ","4) 目的を追加する: 失われた聖杯
      TEXT
    )

    payload = message.choice_payload

    _(message.choice_message?).must_equal true
    _(message.thinking_message?).must_equal false
    _(payload["prompt"]).must_equal "次に追加したい要素を選んでください。番号で回答してください。"
    _(payload["choices"]).must_equal [
      "1) 仲間を追加する: 放浪の薬草師ミナ",
      "2) 敵対者を追加する: 王都の陰謀を操る影の宰相",
      "3) 舞台を追加する: 砂漠のオアシス都市ウィルダ"
    ]
  end

  it "replaces message bubble when chunk becomes a choice payload" do
    user = create(:user)
    chat = create(:chat, user:)

    message = chat.messages.create!(
      role: "assistant",
      content: { type: "choices", prompt: "選んでください", choices: [ "A" ] }.to_json
    )

    message.singleton_class.class_eval do
      attr_accessor :replaced_called, :appended_called

      def broadcast_replace_to(*, **)
        self.replaced_called = true
      end

      def broadcast_append_to(*, **)
        self.appended_called = true
      end
    end

    message.broadcast_append_chunk("ignored")

    _(message.replaced_called).must_equal true
    _(message.appended_called).must_be_nil
  end
end
