require "test_helper"

describe McpAuth do
  it "signs and verifies user id" do
    user = FactoryBot.create(:user)
    signature = McpAuth.sign_user_id(user.id)

    _(McpAuth.verify_user_id(signature)).must_equal user.id
  end

  it "returns nil for invalid signature" do
    _(McpAuth.verify_user_id("invalid")).must_be_nil
  end
end
