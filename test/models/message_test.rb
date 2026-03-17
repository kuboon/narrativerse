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
end
