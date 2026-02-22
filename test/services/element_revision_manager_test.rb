require "test_helper"

class ElementRevisionManagerTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(name: "Author")
    @element = Element.create!(user: @user, element_type: "Character", name: "Hero")
    @scene = Scene.create!(user: @user, text: "Scene")
    @plot = Plot.create!(user: @user, title: "Plot", scene: @scene)
    PlotSceneLink.create!(plot: @plot, scene: @scene, next_scene: nil)
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

  test "updates owned plot elements to latest revision" do
    initial = ElementRevisionManager.new(element: @element, user: @user, revision_params: { summary: "Lead" }).create_initial
    plot_element = PlotElement.create!(plot: @plot, element: @element, element_revision: initial)

    updated = ElementRevisionManager.new(element: @element, user: @user, revision_params: { summary: "Update" }).create_next

    plot_element.reload
    assert_equal updated.id, plot_element.element_revision_id
  end
end
