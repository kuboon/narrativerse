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

  it "sets plot.scene_id when first scene is created for a draft plot" do
    post session_path, params: { user_id: owner.id }
    draft_plot = Plot.create!(user: owner)

    assert_difference [ "Scene.count", "PlotSceneLink.count" ], +1 do
      post plot_plot_scenes_path(draft_plot), params: { scene: { text: "最初のシーン" } }
    end

    assert_equal Scene.order(:id).last.id, draft_plot.reload.scene_id
  end

  it "forbids non-owner from updating via plot_scene_path" do
    post session_path, params: { user_id: other_user.id }

    link = plot.plot_scene_links.first
    patch plot_scene_path(link), params: { scene: { text: "Bad edit" } }

    assert_response :forbidden
    _(link.reload.scene.text).wont_equal "Bad edit"
  end

  it "rerenders scene form with a single scene text input when create fails" do
    post session_path, params: { user_id: owner.id }
    plot

    post plot_plot_scenes_path(plot), params: { scene: { text: "" } }

    assert_response :unprocessable_entity
    assert_select "input[name='scene[text]']", count: 1
  end

  it "redirects to forked plot page after adding branch" do
    post session_path, params: { user_id: other_user.id }
    source_link = plot.plot_scene_links.first

    assert_difference "Plot.count", +1 do
      post fork_plot_scene_path(source_link)
    end

    forked_plot = Plot.order(:id).last
    assert_redirected_to plot_path(forked_plot)
  end
end
