require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  extend Minitest::Spec::DSL

  it "shows a participation-focused landing page with latest 12 plots and elements" do
    author = create(:user)
    created_plots = []

    13.times do |i|
      created_plots << create(:plot, user: author, title: "プロット#{i}", summary: "概要#{i}")
      Element.create!(user: author, element_type: "Character", name: "要素#{i}")
    end

    newest_plot = created_plots.last

    get root_path

    assert_response :success
    assert_select "main.landing-home", count: 1
    assert_select "h1", text: /みんなで広げる、/
    assert_select "a", text: "参加する (ユーザー作成)", count: 1
    assert_select ".stat-chip", text: /#{Regexp.escape(Plot.count.to_s)}\s*公開プロット/, count: 1
    assert_select ".stat-chip", text: /#{Regexp.escape(Element.count.to_s)}\s*共有要素/, count: 1
    assert_select ".stat-chip", text: /12\s*新着表示中/, count: 1
    assert_select "section.grid .cards .card", count: 24
    assert_select "section.grid .cards .card h3", text: "プロット0", count: 0
    assert_select "section.grid .cards .card h3", text: "要素0", count: 0
    assert_select "a.card-link[href='#{reader_path(newest_plot)}']", count: 1
    assert_select "a[href='#{plot_path(newest_plot)}']", count: 0
    assert_select "a", text: "開く", count: 0
  end

  it "switches hero call-to-action for logged-in users" do
    user = create(:user)

    post session_path, params: { user_id: user.id }
    get root_path

    assert_response :success
    assert_select ".user-menu-trigger", text: user.name
    assert_select "a[href='#{mypage_path}']", text: "マイページ", count: 1
    assert_select "a", text: "新しいプロットを書く", count: 1
    assert_select "a", text: "参加する (ユーザー作成)", count: 0
  end
end
