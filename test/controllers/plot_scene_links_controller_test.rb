require "test_helper"

class PlotSceneLinksControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(name: "Owner")
    @scene1 = Scene.create!(user: @user, text: "Scene 1")
    @scene2 = Scene.create!(user: @user, text: "Scene 2")
    @plot = Plot.create!(user: @user, title: "Plot", scene: @scene1)
    @link1 = PlotSceneLink.create!(plot: @plot, scene: @scene1, next_scene: @scene2)
    @link2 = PlotSceneLink.create!(plot: @plot, scene: @scene2, next_scene: nil)
  end

  test "creates a new scene and appends to plot" do
    post session_path, params: { user_id: @user.id }

    assert_difference "Scene.count", 1 do
      assert_difference "PlotSceneLink.count", 1 do
        post plot_plot_scene_links_path(@plot), params: { scene: { text: "New scene" } }
      end
    end

    @link2.reload
    assert_equal Scene.order(created_at: :desc).first.id, @link2.next_scene_id
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
