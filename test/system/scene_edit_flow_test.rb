require "application_system_test_case"

class SceneEditFlowTest < ApplicationSystemTestCase
  test "owner edits inline without navigation" do
    owner = create(:user)
    other = create(:user)

    scene = create(:scene, user: other)
    plot = create(:plot, user: owner, scene:)
    link = create(:plot_scene_link, plot:, scene:, next_scene_id: nil)

    visit new_session_path
    find('select[name="user_id"]').find("option[value='#{owner.id}']").select_option
    within "form" do
      click_on "ログイン"
    end

    assert_selector ".user-pill", text: "#{owner.name} としてログイン中"

    visit plot_path(plot)

    within "#link-#{link.id}" do
      find(".scene-display", visible: true).click
      assert_selector ".scene-editor textarea", visible: true
      find(".scene-editor textarea").set("Owner edit")
      click_on "保存"
      assert_text "Owner edit"
    end

    link.reload
    assert_equal "Owner edit", link.scene.text
    assert_current_path plot_path(plot)
  end

  test "non-owner cannot edit inline" do
    owner = create(:user)
    other = create(:user)

    scene = create(:scene, user: owner)
    plot = create(:plot, user: owner, scene:)
    link = create(:plot_scene_link, plot:, scene:)

    visit new_session_path
    find('select[name="user_id"]').find("option[value='#{other.id}']").select_option
    within "form" do
      click_on "ログイン"
    end

    assert_selector ".user-pill", text: "#{other.name} としてログイン中"

    visit plot_path(plot)

    within "#link-#{link.id}" do
      assert_no_selector ".scene-editor"
      find(".scene-display", visible: true).click
      assert_no_selector ".scene-editor"
    end
  end

  test "switching to another scene auto-saves the first" do
    owner = create(:user)
    scene1 = create(:scene, user: owner, text: "First scene")
    scene2 = create(:scene, user: owner, text: "Second scene")
    plot = create(:plot, user: owner, scene: scene1)
    link1 = create(:plot_scene_link, plot:, scene: scene1, next_scene: scene2)
    link2 = create(:plot_scene_link, plot:, scene: scene2, next_scene_id: nil)

    visit new_session_path
    find('select[name="user_id"]').find("option[value='#{owner.id}']").select_option
    within "form" do
      click_on "ログイン"
    end

    assert_selector ".user-pill", text: "#{owner.name} としてログイン中"
    visit plot_path(plot)

    # Open editor for first scene and type new text
    within "#link-#{link1.id}" do
      find(".scene-display", visible: true).click
      assert_selector ".scene-editor textarea", visible: true
      find(".scene-editor textarea").set("Edited first")
    end

    # Tap second scene — should auto-save first and open second editor
    within "#link-#{link2.id}" do
      find(".scene-display", visible: true).click
      assert_selector ".scene-editor textarea", visible: true
    end

    # First editor should be hidden now
    within "#link-#{link1.id}" do
      assert_no_selector ".scene-editor textarea", visible: true
    end

    link1.reload
    assert_equal "Edited first", link1.scene.text
  end
end
