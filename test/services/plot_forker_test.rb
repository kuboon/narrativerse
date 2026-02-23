require "test_helper"

describe PlotForker do
  let(:user) { User.create!(name: "Forker") }
  let(:other_user) { User.create!(name: "Other") }
  let(:scene1) { Scene.create!(user: other_user, text: "Scene 1") }
  let(:scene2) { Scene.create!(user: other_user, text: "Scene 2") }
  let(:plot) { Plot.create!(user: other_user, title: "Plot", scene: scene1) }
  let(:link1) { PlotSceneLink.create!(plot: plot, scene: scene1, next_scene: scene2) }
  let(:link2) { PlotSceneLink.create!(plot: plot, scene: scene2, next_scene: nil) }

  it "creates a new plot and link" do
    result = PlotForker.new(plot: plot, link: link2, user: user).call

    _(result[:plot].persisted?).must_equal true
    _(result[:link].persisted?).must_equal true
    _(result[:plot].parent_plots.first.id).must_equal plot.id
    _(result[:plot].scene_id).must_equal scene2.id
  end

  it "prevents forking own lineage" do
    _ { PlotForker.new(plot: plot, link: link2, user: other_user).call }.must_raise ArgumentError
  end
end
