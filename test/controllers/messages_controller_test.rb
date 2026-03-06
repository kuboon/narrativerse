require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  extend Minitest::Spec::DSL
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:plot) { create(:plot, user:) }

  it "renders context hidden fields on chat screen" do
    post session_path, params: { user_id: user.id }

    get chat_path, params: { plot_id: plot.id, scene_id: plot.scene_id }

    assert_response :success
    assert_select "input[name='message[plot_id]'][value='#{plot.id}']", count: 1
    assert_select "input[name='message[scene_id]'][value='#{plot.scene_id}']", count: 1
  end

  it "enqueues chat response job with plot and scene context" do
    post session_path, params: { user_id: user.id }

    chat = user.chats.create!

    assert_enqueued_with(job: ChatResponseJob, args: [ chat.id, "続きを提案して", plot.id.to_s, plot.scene_id.to_s ]) do
      post chat_messages_path, params: {
        message: {
          content: "続きを提案して",
          plot_id: plot.id,
          scene_id: plot.scene_id
        }
      }
    end

    assert_response :redirect
    assert_redirected_to chat_path
  end
end
