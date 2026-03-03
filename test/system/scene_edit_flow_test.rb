require "application_system_test_case"

class SceneEditFlowTest < ApplicationSystemTestCase
  test "owner edits inline without navigation" do
    skip "Editor interactions disabled per user request"
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
    skip "Editor interactions disabled per user request"
  end
end
