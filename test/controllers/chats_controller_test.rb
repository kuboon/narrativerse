require "test_helper"

class ChatsControllerTest < ActionDispatch::IntegrationTest
  extend Minitest::Spec::DSL

  let(:user) { create(:user) }

  it "seeds initial choices for untitled plot when autostart is requested" do
    plot = create(:plot, user:, title: nil)
    post session_path, params: { user_id: user.id }

    assert_difference "Message.count", +1 do
      get chat_path, params: { plot_id: plot.id, autostart: "1" }
    end

    assert_response :success

    message = user.chats.first.messages.order(:id).last
    payload = JSON.parse(message.content)

    assert_equal "assistant", message.role
    assert_equal "choices", payload["type"]
    assert_equal "何から始めましょうか？", payload["prompt"]
    assert_equal [
      "登場人物や場面を先に決める",
      "あらすじを先に決める",
      "何も決まっていないので、提案してほしい"
    ], payload["choices"]

    assert_no_difference "Message.count" do
      get chat_path, params: { plot_id: plot.id, autostart: "1" }
    end
  end

  it "does not seed initial choices for titled plot" do
    plot = create(:plot, user:, title: "タイトルあり")
    post session_path, params: { user_id: user.id }

    assert_no_difference "Message.count" do
      get chat_path, params: { plot_id: plot.id, autostart: "1" }
    end

    assert_response :success
  end
end
