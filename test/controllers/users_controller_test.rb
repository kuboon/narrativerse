require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  extend Minitest::Spec::DSL

  it "redirects to login when opening mypage without session" do
    get mypage_path

    assert_redirected_to new_session_path
    follow_redirect!
    assert_select ".flash.error", text: /ログインが必要です/
  end

  it "shows only current user's plots and elements" do
    current_user = create(:user, name: "マイユーザー")
    other_user = create(:user, name: "ほかユーザー")

    own_plot = create(:plot, user: current_user, title: "自分のプロット", summary: "自分だけ")
    create(:plot, user: other_user, title: "他人のプロット")

    own_element = create(:element, user: current_user, name: "自分の要素", element_type: "Character")
    create(:element, user: other_user, name: "他人の要素", element_type: "Item")

    post session_path, params: { user_id: current_user.id }
    get mypage_path

    assert_response :success
    assert_select "h1", text: "#{current_user.name}のマイページ", count: 1
    assert_select "#mypage-plots .card h3", text: own_plot.title, count: 1
    assert_select "#mypage-plots .card h3", text: "他人のプロット", count: 0
    assert_select "#mypage-elements .card h3", text: own_element.name, count: 1
    assert_select "#mypage-elements .card h3", text: "他人の要素", count: 0
  end

  it "filters plots and elements independently on mypage" do
    current_user = create(:user)

    matching_plot = create(:plot, user: current_user, title: "海賊の冒険", summary: "航海")
    create(:plot, user: current_user, title: "都市の日常", summary: "平和")

    matching_element = create(:element, user: current_user, name: "古代の剣", element_type: "Item")
    create(:element, user: current_user, name: "王都", element_type: "Field")

    post session_path, params: { user_id: current_user.id }
    get mypage_path, params: { plot_q: "冒険", element_q: "剣" }

    assert_response :success
    assert_select "#mypage-plots .card", count: 1
    assert_select "#mypage-plots .card h3", text: matching_plot.title, count: 1
    assert_select "#mypage-elements .card", count: 1
    assert_select "#mypage-elements .card h3", text: matching_element.name, count: 1
  end
end
