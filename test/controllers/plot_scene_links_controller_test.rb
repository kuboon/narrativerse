require "test_helper"

class PlotSceneLinksControllerTest < ActionDispatch::IntegrationTest
  extend Minitest::Spec::DSL
  include Rails.application.routes.url_helpers

  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:scene1) { create(:scene, user: other_user) }
  let(:scene2) { create(:scene, user: other_user) }
  let(:plot) { create(:plot, user: other_user, scene: scene1) }
  let(:link1) { create(:plot_scene_link, plot:, scene: scene1, next_scene: scene2) }
  let(:link2) { create(:plot_scene_link, plot:, scene: scene2, next_scene: nil) }

  before do
    link1
    link2
  end

  it "creates a new scene and appends to plot" do
    post session_path, params: { user_id: user.id }

    own_plot = create(:plot, user:, scene: scene1)
    create(:plot_scene_link, plot: own_plot, scene: scene1, next_scene: nil)

    assert_difference "Scene.count", +1 do
      post plot_plot_scene_links_path(own_plot), params: { scene: { text: "New scene" } }
    end

    last_link = PlotSceneLink.find_by(plot_id: own_plot.id, next_scene_id: Scene.order(created_at: :desc).first.id)
    _(last_link).wont_be_nil
  end

  it "fork creates a new plot linked to parent" do
    post session_path, params: { user_id: user.id }

    assert_difference "Plot.count", +1 do
      post fork_plot_scene_link_path(link2)
    end

    new_plot = Plot.order(created_at: :desc).first
    _(new_plot.parent_plot_ids.first).must_equal plot.id
    _(new_plot.scene_id).must_equal plot.scene_id
    _(new_plot.plot_scene_links.count).must_equal 1
  end

  it "allows plot owner to update linked scene via plot_scene_path" do
    # plot owned by user
    post session_path, params: { user_id: user.id }

    own_plot = create(:plot, user:, scene: scene1)
    link = create(:plot_scene_link, plot: own_plot, scene: scene1, next_scene: nil)

    patch plot_scene_path(link), params: { scene: { text: "Owner edit" } }

    assert_redirected_to plot_path(own_plot)
    _(link.reload.scene.text).must_equal "Owner edit"
  end

  it "forbids non-owner from updating via plot_scene_path" do
    post session_path, params: { user_id: other_user.id }

    own_plot = create(:plot, user:, scene: scene1)
    link = create(:plot_scene_link, plot: own_plot, scene: scene1, next_scene: nil)

    patch plot_scene_path(link), params: { scene: { text: "Bad edit" } }

    assert_response :forbidden
    _(link.reload.scene.text).wont_equal "Bad edit"
  end
end
