require "application_system_test_case"

class SceneEditFlowTest < ApplicationSystemTestCase
  test "owner edits inline without navigation" do
    owner = create(:user)

    plot = create(:plot, user: owner)
    link = plot.plot_scene_links.first

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
    end
    find("body").click # blur textarea to trigger save

    link.reload
    assert_equal "Owner edit", link.scene.text
    assert_current_path plot_path(plot)
  end

  test "non-owner cannot edit inline" do
    owner = create(:user)
    other = create(:user)

    plot = create(:plot, user: owner)
    link = plot.plot_scene_links.first

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
    plot = create(:plot, user: owner, scenes_count: 2)
    links = plot.plot_scene_links.order(:created_at)
    link1 = links.first
    link2 = links.last

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

    # First editor should be closed and show saved text
    within "#link-#{link1.id}" do
      assert_no_selector ".scene-editor textarea", visible: true
      assert_text "Edited first"
    end

    link1.reload
    assert_equal "Edited first", link1.scene.text
  end
end
