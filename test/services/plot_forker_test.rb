require "test_helper"

class PlotForkerTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(name: "Forker")
    @scene1 = Scene.create!(user: @user, text: "Scene 1")
    @scene2 = Scene.create!(user: @user, text: "Scene 2")
    @plot = Plot.create!(user: @user, title: "Plot", scene: @scene1)
    @link1 = PlotSceneLink.create!(plot: @plot, scene: @scene1, next_scene: @scene2)
    @link2 = PlotSceneLink.create!(plot: @plot, scene: @scene2, next_scene: nil)
  end

  test "creates a new plot and link" do
    result = PlotForker.new(plot: @plot, link: @link2, user: @user).call

    assert result[:plot].persisted?
    assert result[:link].persisted?
    assert_equal @plot.id, result[:plot].parent_plots.first.id
    assert_equal @scene2.id, result[:plot].scene_id
  end
end
