require "test_helper"

describe ElementRevisionManager do
  let(:user) { User.create!(name: "Author") }
  let(:element) { Element.create!(user: user, element_type: "Character", name: "Hero") }
  let(:scene) { Scene.create!(user: user, text: "Scene") }
  let(:plot) { Plot.create!(user: user, title: "Plot", scene: scene) }

  before do
    PlotSceneLink.create!(plot: plot, scene: scene, next_scene: nil)
  end

  it "creates initial revision" do
    manager = ElementRevisionManager.new(element: element, user: user, revision_params: { summary: "Lead" })
    revision = manager.create_initial

    _(revision.persisted?).must_equal true
    _(revision.revision).must_equal 1
  end

  it "creates next revision" do
    ElementRevisionManager.new(element: element, user: user, revision_params: { summary: "Lead" }).create_initial
    manager = ElementRevisionManager.new(element: element, user: user, revision_params: { summary: "Update" })
    revision = manager.create_next

    _(revision.persisted?).must_equal true
    _(revision.revision).must_equal 2
  end

  it "updates owned plot elements to latest revision" do
    initial = ElementRevisionManager.new(element: element, user: user, revision_params: { summary: "Lead" }).create_initial
    plot_element = PlotElement.create!(plot: plot, element: element, element_revision: initial)

    updated = ElementRevisionManager.new(element: element, user: user, revision_params: { summary: "Update" }).create_next

    plot_element.reload
    _(plot_element.element_revision_id).must_equal updated.id
  end
end
