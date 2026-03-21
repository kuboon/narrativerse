require "test_helper"

class MessageTest < ActiveSupport::TestCase
  extend Minitest::Spec::DSL

  it "builds choice payload from content_raw json" do
    message = Message.new(
      role: "assistant",
      content_raw: {
        question: "次のいずれかを選んでください。",
        choices: [
          "1) 追加する",
          "2) スキップする"
        ]
      }.to_json
    )

    _(message.choice_payload).must_equal(
      {
        "question" => "次のいずれかを選んでください。",
        "choices" => [
          "1) 追加する",
          "2) スキップする"
        ]
      }
    )
  end

  it "builds choice payload from serialized content_raw array" do
    message = Message.new(
      role: "assistant",
      content_raw: [
        "content_raw",
        { question: "番号を選んでください。", choices: [ "1", "2" ] }.to_json
      ]
    )

    _(message.choice_payload).must_equal(
      {
        "question" => "番号を選んでください。",
        "choices" => [ "1", "2" ]
      }
    )
  end

  it "extracts tool_calls from content_raw" do
    message = Message.new(
      role: "assistant",
      content_raw: {
        "tool_calls" => {
          "call_123" => {
            "id" => "call_123",
            "name" => "test_tool",
            "arguments" => { "foo" => "bar" }
          }
        }
      }
    )

    tc = message.extract_tool_calls["call_123"]
    _(tc).must_be_kind_of RubyLLM::ToolCall
    _(tc.id).must_equal "call_123"
    _(tc.name).must_equal "test_tool"
    _(tc.arguments).must_equal({ "foo" => "bar" })
  end

  it "extracts tool_call_id from content_raw" do
    message = Message.new(
      role: "tool",
      content_raw: { "tool_call_id" => "call_123" }
    )

    _(message.extract_tool_call_id).must_equal "call_123"
  end
end
