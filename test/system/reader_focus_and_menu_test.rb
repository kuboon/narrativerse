require "application_system_test_case"

class ReaderFocusAndMenuTest < ApplicationSystemTestCase
  test "tapping a scene moves focus" do
    owner = create(:user)
    plot = create(:plot, user: owner, scenes_count: 3)
    links = plot.plot_scene_links.order(:id)
    target_scene_id = links.second.scene_id

    visit reader_path(plot)

    find("#scene-#{target_scene_id}").click

    assert_current_path reader_scene_path(plot, target_scene_id), ignore_query: true
    assert_selector "article.scene.focus#scene-#{target_scene_id}"
  end

  test "three-dot menu opens as popup" do
    owner = create(:user)
    plot = create(:plot, user: owner, scenes_count: 2)
    source_scene = plot.plot_scene_links.order(:id).first.scene
    branch_plot = create(:plot, user: owner, scene: source_scene, scenes_count: 1)
    branch_next_scene = create(:scene, user: owner)
    branch_link = branch_plot.plot_scene_links.find_by!(scene_id: source_scene.id)
    branch_link.update!(next_scene: branch_next_scene)
    create(:plot_scene_link, plot: branch_plot, scene: branch_next_scene, next_scene: nil)

    visit reader_path(plot)

    within "#scene-#{source_scene.id}" do
      find("summary.scene-branch-menu-toggle").click
      assert_selector "details.scene-branch-menu[open]"
      assert_selector "a.scene-branch-menu-item", text: "分岐: #{branch_plot.title}"
    end
  end
end
