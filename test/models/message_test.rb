require "test_helper"

class MessageTest < ActiveSupport::TestCase
  extend Minitest::Spec::DSL

  it "builds choice payload from structured assistant content" do
    message = Message.new(
      role: "assistant",
      content: { question: "次のいずれかを選んでください。", choices: [ "1) 追加する", " ", "2) スキップする" ] }.to_json
    )

    _(message.choice_payload).must_equal(
      "question" => "次のいずれかを選んでください。",
      "choices" => [ "1) 追加する", "2) スキップする" ]
    )
  end

  it "has no choice payload for plain text or user messages" do
    _(Message.new(role: "assistant", content: "こんにちは").choice_payload).must_be_nil
    _(Message.new(role: "user", content: { question: "q", choices: [ "a" ] }.to_json).choice_payload).must_be_nil
  end

  it "parses tool result payloads" do
    message = Message.new(role: "tool", content: { status: "ok", message: "シーンを追加しました。" }.to_json)

    _(message.tool_payload).must_equal("status" => "ok", "message" => "シーンを追加しました。")
    _(Message.new(role: "assistant", content: "{}").tool_payload).must_be_nil
  end
end
