require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  extend Minitest::Spec::DSL

  it "streams chat response and saves messages" do
    user = create(:user)
    plot = create(:plot, user: user)
    chat = create(:chat, user: user, messages_count: 0)

    # Login
    post session_path, params: { user_id: user.id }

    choice = "プロットの要約を教えて"

    # Stub the LLM response
    RubyLLM::StubProvider.stub_chat("これはプロットの要約です。")

    assert_difference -> { chat.messages.count }, 2 do # User message + Assistant message
      post messages_path, params: {
        message: {
          content: choice,
          plot_id: plot.id
        }
      }
    end

    assert_response :success
    assert_equal "text/event-stream", response.headers["Content-Type"]

    # Verify user message
    user_msg = chat.messages.order(:id).last(2).first
    _(user_msg.content).must_equal choice

    # Verify assistant message
    assistant_msg = chat.messages.order(:id).last
    _(assistant_msg.content).must_equal "これはプロットの要約です。"

    # Verify SSE content (Turbo Streams)
    # The body will contain multiple SSE events:
    # event: turbo-stream
    # data: <turbo-stream action="append" target="messages">...

    # Check for user message append
    _(response.body).must_match /turbo-stream action="append" target="messages"/
    _(response.body).must_match /#{choice}/

    # Check for assistant message append (container)
    # It will have the message ID
    _(response.body).must_match /id="message_#{assistant_msg.id}"/

    # Check for chunk append
    _(response.body).must_match /これはプロットの要約です。/
  end

  it "handles tool-like responses (choices)" do
    user = create(:user)
    plot = create(:plot, user: user)
    chat = create(:chat, user: user, messages_count: 0)

    post session_path, params: { user_id: user.id }

    # Stub with a choice payload
    # Note: Our StubProvider currently only supports simple text or full Bedrock hashes.
    # To test choices, we need a response that triggers choice_payload in Message model.
    # Message#choice_payload looks at content_raw.

    response_payload = {
      "output" => {
        "message" => {
          "role" => "assistant",
          "content" => [
            { "text" => '{"question": "どうしますか？", "choices": ["次へ", "やめる"]}' }
          ]
        }
      },
      "usage" => { "inputTokens" => 10, "outputTokens" => 20 }
    }

    RubyLLM::StubProvider.stub_chat(response_payload)

    post messages_path, params: {
      message: {
        content: "次は？",
        plot_id: plot.id
      }
    }

    assert_response :success
    assistant_msg = chat.messages.find_by(role: "assistant")

    # In our controller, if choice_payload is present, we stream a replace
    _(response.body).must_match /turbo-stream action="replace" target="message_#{assistant_msg.id}_content"/
    _(response.body).must_match /どうしますか？/
    _(response.body).must_match /次へ/
  end
end
