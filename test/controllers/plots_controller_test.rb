require "test_helper"

class PlotsControllerTest < ActionDispatch::IntegrationTest
  extend Minitest::Spec::DSL

  let(:owner) { create(:user) }
  let(:plot) { create(:plot, user: owner) }

  it "does not route post /plots" do
    post plots_path, params: { plot: { title: "unused" } }

    assert_response :not_found
  end

  it "redirects edit path to show" do
    post session_path, params: { user_id: owner.id }

    get edit_plot_path(plot)

    assert_redirected_to plot_path(plot)
  end

  it "does not show parent plot row when there is no parent" do
    get plot_path(plot)

    assert_response :success
    assert_select "span.meta-label", text: "親プロット", count: 0
    assert_select "span", text: "なし", count: 0
  end

  it "shows parent plot links when there are parents" do
    parent_plot = Plot.create!(user: owner, title: "親プロット")
    child_plot = Plot.create!(user: owner, title: "子プロット", parent_plot_ids: [ parent_plot.id ])

    get plot_path(child_plot)

    assert_response :success
    assert_select "span.meta-label", text: "親プロット", count: 1
    assert_select "a[href='#{plot_path(parent_plot)}']", text: ActionController::Base.helpers.strip_tags(parent_plot.title), count: 1
  end
end
