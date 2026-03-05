require "application_system_test_case"

class ReaderFocusAndMenuTest < ApplicationSystemTestCase
  test "tapping a scene moves focus" do
    owner = create(:user)
    plot = create(:plot, user: owner, scenes_count: 3)
    links = plot.plot_scene_links.order(:id)
    first_scene_id = links.first.scene_id
    target_scene_id = links.second.scene_id

    visit reader_path(plot)
    assert_selector "article.scene.focus#scene-#{first_scene_id}"

    find("#scene-#{target_scene_id}").click

    assert_current_path reader_path(plot), ignore_query: true
    assert_selector "article.scene.focus#scene-#{target_scene_id}"
    assert_no_selector "article.scene.focus#scene-#{first_scene_id}"
  end

  test "three-dot menu opens as popup" do
    owner = create(:user)
    viewer = create(:user)
    plot = create(:plot, user: owner, scenes_count: 3)
    focus_scene_id = plot.plot_scene_links.order(:id).first.scene_id

    visit new_session_path
    find('select[name="user_id"]').find("option[value='#{viewer.id}']").select_option
    within "form" do
      click_on "ログイン"
    end

    visit reader_path(plot)

    assert_selector "#scene-#{focus_scene_id} summary.scene-branch-menu-toggle"

    within "#scene-#{focus_scene_id}" do
      find("summary.scene-branch-menu-toggle").click
      assert_selector "details.scene-branch-menu[open]"
      assert_selector "a.scene-branch-menu-item", text: "分岐を追加"
    end
  end
end
