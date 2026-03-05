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
    get reader_scene_path(plot, target_scene_id)

    assert_response :success
    assert_select "[data-reader-flow][data-focus-scene-id='#{target_scene_id}']", count: 1
    assert_select "article.scene.focus#scene-#{target_scene_id}", count: 1
    assert_select "article.scene.focus", count: 1
  end

  it "falls back to plot start scene when scene_id is invalid" do
    invalid_scene_id = Scene.maximum(:id).to_i + 100
    get reader_scene_path(plot, invalid_scene_id)

    assert_response :success
    first_scene_id = ordered_scene_ids.first
    assert_select "[data-reader-flow][data-focus-scene-id='#{first_scene_id}']", count: 1
    assert_select "article.scene.focus#scene-#{first_scene_id}", count: 1
  end
end
