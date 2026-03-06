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
end
