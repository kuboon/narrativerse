require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  extend Minitest::Spec::DSL
  include ActiveJob::TestHelper

  setup do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  teardown do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "enqueues a chat response job for posted content" do
    user = create(:user)
    chat = create(:chat, user:)
    choice = "1) 初期要素セットを追加して土台を作る"

    post session_path, params: { user_id: user.id }

    assert_enqueued_with(job: ChatResponseJob) do
      post messages_path, params: {
        message: {
          content: choice,
          plot_id: "plot-123"
        }
      }
    end

    assert_response :no_content
    _(enqueued_jobs.last[:args].first).must_equal chat.id
    _(enqueued_jobs.last[:args].second["content"]).must_equal choice
    _(enqueued_jobs.last[:args].second["plot_id"]).must_equal "plot-123"
  end
end
