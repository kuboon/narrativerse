require "test_helper"

class ReaderControllerTest < ActionDispatch::IntegrationTest
  extend Minitest::Spec::DSL

  let(:owner) { create(:user) }
  let(:plot) { create(:plot, user: owner, scenes_count: 3) }

  let(:ordered_scene_ids) do
    plot.plot_scene_links.order(:id).pluck(:scene_id)
  end

  it "focuses first scene when scene_id is absent" do
    get reader_path(plot)

    assert_response :success
    assert_select ".site-header h1.reader-title", text: plot.title, count: 1
    assert_select ".site-header [data-reader-progress]", count: 1
    first_scene_id = ordered_scene_ids.first
    assert_select "[data-reader-flow][data-focus-scene-id='#{first_scene_id}']", count: 1
    assert_select "article.scene.focus#scene-#{first_scene_id}", count: 1
  end

  it "focuses requested scene when scene_id is present" do
    target_scene_id = ordered_scene_ids.second
    get reader_path(plot, target_scene_id)

    assert_response :success
    assert_select "[data-reader-flow][data-focus-scene-id='#{target_scene_id}']", count: 1
    assert_select "article.scene.focus#scene-#{target_scene_id}", count: 1
    assert_select "article.scene.focus", count: 1
  end

  it "falls back to plot start scene when scene_id is invalid" do
    invalid_scene_id = Scene.maximum(:id).to_i + 100
    get reader_path(plot, invalid_scene_id)

    assert_response :success
    first_scene_id = ordered_scene_ids.first
    assert_select "[data-reader-flow][data-focus-scene-id='#{first_scene_id}']", count: 1
    assert_select "article.scene.focus#scene-#{first_scene_id}", count: 1
  end

  it "shows branch menu at next scene and no legacy branch links" do
    source_scene_id = ordered_scene_ids.second
    source_scene = Scene.find(source_scene_id)
    branch_plot = create_branch_from(source_scene: source_scene, user: owner)
    main_source_link = plot.plot_scene_links.find_by!(scene_id: source_scene_id)
    target_scene_id = main_source_link.next_scene_id

    get reader_path(plot, source_scene_id)

    assert_response :success
    assert_select ".story-branch-links", count: 0
    assert_select "article.scene .scene-branch-menu", count: 1
    assert_select "#scene-#{source_scene_id} .scene-branch-menu", count: 0
    assert_select "#scene-#{target_scene_id} a.scene-branch-menu-item", text: "分岐: #{branch_plot.title}", count: 1
    assert_select "a.scene-branch-menu-item", text: "分岐を追加", count: 0
  end

  it "shows add-branch in all popups while logged in" do
    branch_scene_id = ordered_scene_ids.first
    focused_scene_id = ordered_scene_ids.second
    branch_scene = Scene.find(branch_scene_id)
    create_branch_from(source_scene: branch_scene, user: owner)
    viewer = create(:user)

    post session_path, params: { user_id: viewer.id }
    get reader_path(plot, focused_scene_id)

    assert_response :success
    assert_select "article.scene .scene-branch-menu", count: 3
    assert_select "article.scene .scene-branch-menu.focus-only-menu", count: 2
    assert_select "#scene-#{focused_scene_id} .scene-branch-menu", count: 1
    assert_select ".scene-branch-menu a.scene-branch-menu-item", text: "分岐を追加", count: 3
  end

  private

  def create_branch_from(source_scene:, user:)
    branch_plot = create(:plot, user:, scene: source_scene, scenes_count: 1)
    next_scene = create(:scene, user:)

    branch_link = branch_plot.plot_scene_links.find_by!(scene_id: source_scene.id)
    branch_link.update!(next_scene:)
    create(:plot_scene_link, plot: branch_plot, scene: next_scene, next_scene: nil)

    branch_plot
  end
end
