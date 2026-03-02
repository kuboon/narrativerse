require "test_helper"

class PlotSceneLinksControllerTest < ActionDispatch::IntegrationTest
  extend Minitest::Spec::DSL
  include Rails.application.routes.url_helpers

  let(:owner) { create(:user) }
  let(:other_user) { create(:user) }
  let(:plot) { create(:plot, user: owner, scenes_count: 2) }

  it "creates a new scene and appends to plot" do
    post session_path, params: { user_id: owner.id }
    plot

    assert_difference "Scene.count", +1 do
      post plot_plot_scenes_path(plot), params: { scene: { text: "New scene" } }
    end

    last_link = PlotSceneLink.find_by(plot_id: plot.id, next_scene_id: Scene.order(created_at: :desc).first.id)
    _(last_link).wont_be_nil
  end

  it "forbids non-owner from updating via plot_scene_path" do
    post session_path, params: { user_id: other_user.id }

    link = plot.plot_scene_links.first
    patch plot_scene_path(link), params: { scene: { text: "Bad edit" } }

    assert_response :forbidden
    _(link.reload.scene.text).wont_equal "Bad edit"
  end
end
