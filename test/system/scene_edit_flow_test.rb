require "application_system_test_case"

class SceneEditFlowTest < ApplicationSystemTestCase
  test "owner edits inline without navigation" do
    owner = User.create!(name: "Owner")
    other = User.create!(name: "Other")

    scene = Scene.create!(user: other, text: "Original")
    plot = Plot.create!(user: owner, title: "Owner Plot", scene: scene)
    link = PlotSceneLink.create!(plot: plot, scene: scene, next_scene_id: nil)

    visit new_session_path
    select owner.name, from: "user_id"
    click_on "ログイン"

    visit plot_path(plot)

    within "#link-#{link.id}" do
      find(".scene-display").click
      assert_selector ".scene-editor textarea", visible: true
      # use textarea selector directly to avoid label lookup issues
      find(".scene-editor textarea").set("Owner edit")
      click_on "保存"
      assert_text "Owner edit"
    end

    link.reload
    assert_equal "Owner edit", link.scene.text
    assert_current_path plot_path(plot)
  end

  test "non-owner cannot edit inline" do
    owner = User.create!(name: "Owner")
    other = User.create!(name: "Other")

    scene = Scene.create!(user: owner, text: "Original")
    plot = Plot.create!(user: owner, title: "Owner Plot", scene: scene)
    link = PlotSceneLink.create!(plot: plot, scene: scene, next_scene_id: nil)

    visit new_session_path
    select other.name, from: "user_id"
    click_on "ログイン"

    visit plot_path(plot)

    within "#link-#{link.id}" do
      assert_no_selector ".scene-editor"
      find(".scene-display").click
      assert_no_selector ".scene-editor"
    end
  end
end
