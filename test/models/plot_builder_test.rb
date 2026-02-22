require "test_helper"

class PlotBuilderTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(name: "Test User")
    @scene1 = Scene.create!(user: @user, text: "Scene 1")
    @scene2 = Scene.create!(user: @user, text: "Scene 2")
    @scene3 = Scene.create!(user: @user, text: "Scene 3")

    @plot_a = Plot.create!(user: @user, title: "Plot A", scene: @scene1)
    @link1 = PlotSceneLink.create!(plot: @plot_a, scene: @scene1, next_scene: @scene2)
    @link2 = PlotSceneLink.create!(plot: @plot_a, scene: @scene2, next_scene: @scene3)
    @link3 = PlotSceneLink.create!(plot: @plot_a, scene: @scene3, next_scene: nil)

    @plot_b = Plot.create!(user: @user, title: "Plot B", scene: @scene2)
    PlotParentLink.create!(child_plot: @plot_b, parent_plot: @plot_a)
    @link_b = PlotSceneLink.create!(plot: @plot_b, scene: @scene2, next_scene: @scene3)
  end

  test "returns previous scene from parent plots when missing in child" do
    payload = PlotBuilder.new(@plot_b.id, @link_b.id).call

    assert_equal @scene2, payload[:scene]
    assert_equal @scene1, payload[:previous_scene]
    assert_equal @scene3, payload[:next_scene]
    assert_equal @plot_b, payload[:plot]
  end

  test "returns next link across parent plots when available" do
    payload = PlotBuilder.new(@plot_b.id, @link_b.id).call

    assert_equal @link3, payload[:next_link]
    assert_equal @scene3, payload[:next_scene]
  end
end
