require "application_system_test_case"

class ChatChoicesTest < ApplicationSystemTestCase
  test "renders choices and streams the reply to the selected one" do
    owner = create(:user)
    plot = create(:plot, user: owner)
    chat = create(:chat, user: owner)
    choice = "2) プロットのタイトルと概要を設定する"

    chat.messages.create!(
      role: "assistant",
      content: {
        question: "現在のプロットは要素がまだありません。共同創作を始めるため、次のいずれかを選んでください。",
        choices: [
          "1) 初期要素セットを追加して土台を作る",
          choice,
          "3) 最初のシーンの雛形を仮案として作成する"
        ]
      }.to_json
    )

    visit new_session_path
    find('select[name="user_id"]').find("option[value='#{owner.id}']").select_option
    within "form" do
      click_on "ログイン"
    end

    visit plot_path(plot)

    find("#chat-float button[popovertarget='chat-popover']").click

    assert_selector "#chat-frame #messages"
    assert_selector "#chat-frame .chat-choice", text: choice
    assert_text "現在のプロットは要素がまだありません。共同創作を始めるため、次のいずれかを選んでください。"

    click_button choice

    within "#chat-frame #messages" do
      assert_selector ".chat-end .chat-bubble", text: choice
      assert_selector ".chat-start .chat-bubble", text: "(no stub registered)"
      assert_no_selector "#message_streaming"
    end
    assert_equal "", find("#new_message textarea").value
    assert_equal %w[user assistant], chat.messages.order(:id).last(2).map(&:role)
  end
end
