require "test_helper"

describe PlotBuilder do
  let(:user) { User.create!(name: "Test User") }
  let(:scene1) { Scene.create!(user: user, text: "Scene 1") }
  let(:scene2) { Scene.create!(user: user, text: "Scene 2") }
  let(:scene3) { Scene.create!(user: user, text: "Scene 3") }
  let(:plot_a) { Plot.create!(user: user, title: "Plot A", scene: scene1) }
  let(:link1) { PlotSceneLink.create!(plot: plot_a, scene: scene1, next_scene: scene2) }
  let(:link2) { PlotSceneLink.create!(plot: plot_a, scene: scene2, next_scene: scene3) }
  let(:link3) { PlotSceneLink.create!(plot: plot_a, scene: scene3, next_scene: nil) }
  let(:plot_b) { Plot.create!(user: user, title: "Plot B", scene: scene2) }
  let(:link_b) { PlotSceneLink.create!(plot: plot_b, scene: scene2, next_scene: scene3) }

  before do
    link1
    link2
    link3
    PlotParentLink.create!(child_plot: plot_b, parent_plot: plot_a)
    link_b
  end

  it "returns previous scene from parent plots when missing in child" do
    payload = PlotBuilder.new(plot_b.id, link_b.id).call

    _(payload[:scene]).must_equal scene2
    _(payload[:previous_scene]).must_equal scene1
    _(payload[:next_scene]).must_equal scene3
    _(payload[:plot]).must_equal plot_b
  end

  it "returns next link across parent plots when available" do
    payload = PlotBuilder.new(plot_b.id, link_b.id).call

    _(payload[:next_link]).must_equal link3
    _(payload[:next_scene]).must_equal scene3
  end
end
