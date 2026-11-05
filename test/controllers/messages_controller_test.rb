require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  extend Minitest::Spec::DSL

  let(:user) { create(:user) }
  let(:plot) { create(:plot, user:) }
  let(:chat) { create(:chat, user:) }

  before do
    chat
    post session_path, params: { user_id: user.id }
  end

  def sse_data(body)
    body.split("\n\n").map do |event|
      event.lines(chomp: true).grep(/\Adata: /).map { |line| line.delete_prefix("data: ") }.join("\n")
    end
  end

  it "streams the reply as turbo-stream SSE events and saves the messages" do
    RubyLLM::StubProvider.stub_chat("これはプロットの要約です。")

    assert_difference -> { chat.messages.count }, 2 do
      post messages_path, params: { message: { content: "プロットの要約を教えて", plot_id: plot.id } }
    end

    assert_response :success
    _(response.media_type).must_equal "text/event-stream"

    user_message, assistant_message = chat.messages.order(:id).last(2)
    _(user_message.role).must_equal "user"
    _(user_message.content).must_equal "プロットの要約を教えて"
    _(assistant_message.role).must_equal "assistant"
    _(assistant_message.content).must_equal "これはプロットの要約です。"

    events = sse_data(response.body)
    _(events).must_be :all?, ->(data) { data.start_with?("<turbo-stream") }
    _(events.first).must_match %r{action="append" target="messages".*id="message_#{user_message.id}"}m
    _(events).must_include %(<turbo-stream action="append" target="message_streaming_content"><template>これはプロットの要約です。</template></turbo-stream>)
    _(events).must_include %(<turbo-stream action="remove" target="message_streaming"></turbo-stream>)
    _(events.last).must_match %r{action="append" target="messages".*id="message_#{assistant_message.id}"}m
  end

  it "renders choices once the structured reply is saved" do
    RubyLLM::StubProvider.stub_chat({ question: "どうしますか？", choices: [ "次へ", "やめる" ] }.to_json)

    post messages_path, params: { message: { content: "次は？", plot_id: plot.id } }

    assert_response :success
    assistant_message = chat.messages.where(role: "assistant").last
    _(assistant_message.choice_payload).must_equal("question" => "どうしますか？", "choices" => [ "次へ", "やめる" ])
    _(sse_data(response.body).last).must_match %r{id="message_#{assistant_message.id}".*chat-choice.*次へ}m
  end

  it "rejects blank content" do
    assert_no_difference -> { Message.count } do
      post messages_path, params: { message: { content: " ", plot_id: plot.id } }
    end

    assert_response :unprocessable_entity
  end
end
