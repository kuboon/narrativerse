require "test_helper"

class PlotsControllerTest < ActionDispatch::IntegrationTest
  extend Minitest::Spec::DSL

  let(:owner) { create(:user) }
  let(:plot) { create(:plot, user: owner) }

  it "creates a draft plot on new and redirects to show" do
    post session_path, params: { user_id: owner.id }

    assert_difference "Plot.count", +1 do
      get new_plot_path
    end

    draft = Plot.order(:id).last
    assert_redirected_to plot_path(draft)

    follow_redirect!
    assert_response :success
    assert_select "a[href='#{new_plot_plot_element_path(draft)}']", text: "要素を追加", count: 1
    assert_select "form[action^='#{plot_plot_scenes_path(draft)}']", count: 1
  end

  it "does not route post /plots" do
    post plots_path, params: { plot: { title: "unused" } }

    assert_response :not_found
  end

  it "redirects edit path to show" do
    post session_path, params: { user_id: owner.id }

    get edit_plot_path(plot)

    assert_redirected_to plot_path(plot)
  end

  it "updates a plot inline with turbo stream" do
    post session_path, params: { user_id: owner.id }

    patch plot_path(plot),
      params: {
        plot: {
          title: "<p><strong>更新タイトル</strong></p>",
          summary: "<p><ruby>更新概要<rt>こうしんがいよう</rt></ruby></p>"
        }
      },
      headers: { "Accept" => Mime[:turbo_stream].to_s }

    assert_response :success
    assert_equal Mime[:turbo_stream].to_s, @response.media_type
    assert_includes @response.body, "target=\"plot-overview-#{plot.id}\""
    assert_includes @response.body, "<ruby>"

    updated_plot = plot.reload
    assert_equal "更新タイトル", ActionController::Base.helpers.strip_tags(updated_plot.title).squish
  end
end
