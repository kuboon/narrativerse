require "test_helper"

class ElementRevisionManagerTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(name: "Author")
    @element = Element.create!(user: @user, element_type: "Character", name: "Hero")
  end

  test "creates initial revision" do
    manager = ElementRevisionManager.new(element: @element, user: @user, revision_params: { summary: "Lead" })
    revision = manager.create_initial

    assert revision.persisted?
    assert_equal 1, revision.revision
  end

  test "creates next revision" do
    ElementRevisionManager.new(element: @element, user: @user, revision_params: { summary: "Lead" }).create_initial
    manager = ElementRevisionManager.new(element: @element, user: @user, revision_params: { summary: "Update" })
    revision = manager.create_next

    assert revision.persisted?
    assert_equal 2, revision.revision
  end
end
