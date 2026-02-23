require "test_helper"

class PlotSceneLinksControllerTest < ActionDispatch::IntegrationTest
  extend Minitest::Spec::DSL
  include Rails.application.routes.url_helpers

  let(:user) { User.create!(name: "Owner") }
  let(:other_user) { User.create!(name: "Other") }
  let(:scene1) { Scene.create!(user: other_user, text: "Scene 1") }
  let(:scene2) { Scene.create!(user: other_user, text: "Scene 2") }
  let(:plot) { Plot.create!(user: other_user, title: "Plot", scene: scene1) }
  let(:link1) { PlotSceneLink.create!(plot: plot, scene: scene1, next_scene: scene2) }
  let(:link2) { PlotSceneLink.create!(plot: plot, scene: scene2, next_scene: nil) }

  before do
    link1
    link2
  end

  it "creates a new scene and appends to plot" do
    post session_path, params: { user_id: user.id }

    own_plot = Plot.create!(user: user, title: "My Plot", scene: scene1)
    PlotSceneLink.create!(plot: own_plot, scene: scene1, next_scene: nil)

    assert_difference "Scene.count", +1 do
      post plot_plot_scene_links_path(own_plot), params: { scene: { text: "New scene" } }
    end

    last_link = PlotSceneLink.find_by(plot_id: own_plot.id, next_scene_id: Scene.order(created_at: :desc).first.id)
    _(last_link).wont_be_nil
  end

  it "fork creates a new plot linked to parent" do
    post session_path, params: { user_id: user.id }

    assert_difference "Plot.count", +1 do
      post fork_plot_plot_scene_link_path(plot, link2)
    end

    new_plot = Plot.order(created_at: :desc).first
    _(new_plot.parent_plots.first.id).must_equal plot.id
    _(new_plot.scene_id).must_equal scene2.id
    _(new_plot.plot_scene_links.count).must_equal 1
  end
end
