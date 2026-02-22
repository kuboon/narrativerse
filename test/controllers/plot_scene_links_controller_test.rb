require "test_helper"

class PlotSceneLinksControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(name: "Owner")
    @other_user = User.create!(name: "Other")
    @scene1 = Scene.create!(user: @other_user, text: "Scene 1")
    @scene2 = Scene.create!(user: @other_user, text: "Scene 2")
    @plot = Plot.create!(user: @other_user, title: "Plot", scene: @scene1)
    @link1 = PlotSceneLink.create!(plot: @plot, scene: @scene1, next_scene: @scene2)
    @link2 = PlotSceneLink.create!(plot: @plot, scene: @scene2, next_scene: nil)
  end

  test "creates a new scene and appends to plot" do
    post session_path, params: { user_id: @user.id }

    own_plot = Plot.create!(user: @user, title: "My Plot", scene: @scene1)
    PlotSceneLink.create!(plot: own_plot, scene: @scene1, next_scene: nil)

    assert_difference "Scene.count", 1 do
      assert_difference "PlotSceneLink.count", 1 do
        post plot_plot_scene_links_path(own_plot), params: { scene: { text: "New scene" } }
      end
    end

    last_link = PlotSceneLink.find_by(plot_id: own_plot.id, next_scene_id: Scene.order(created_at: :desc).first.id)
    assert last_link
  end

  test "fork creates a new plot linked to parent" do
    post session_path, params: { user_id: @user.id }

    assert_difference "Plot.count", 1 do
      assert_difference "PlotParentLink.count", 1 do
        post fork_plot_plot_scene_link_path(@plot, @link2)
      end
    end

    new_plot = Plot.order(created_at: :desc).first
    assert_equal @plot.id, new_plot.parent_plots.first.id
    assert_equal @scene2.id, new_plot.scene_id
    assert_equal 1, new_plot.plot_scene_links.count
  end
end
