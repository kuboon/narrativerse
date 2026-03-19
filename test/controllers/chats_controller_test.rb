require "test_helper"

class ChatsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = FactoryBot.create(:user)
    post session_path, params: { user_id: @user.id }
    FactoryBot.create(:chat, user: @user)
  end

  test "should get chat show" do
    get chat_path
    assert_response :success
    assert_match "メッセージを入力...", @response.body
  end
end
