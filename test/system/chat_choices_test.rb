require "application_system_test_case"

class ChatChoicesTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  setup do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  teardown do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  test "renders content_raw choices and submits the selected text" do
    owner = create(:user)
    plot = create(:plot, user: owner)
    chat = create(:chat, user: owner)
    choice = "2) プロットのタイトルと概要を設定する"

    chat.messages.create!(
      role: "assistant",
      content_raw: {
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

    page.execute_script(<<~JS)
      const form = document.getElementById("new_message")
      form.dataset.submitted = "false"
      form.addEventListener("submit", () => {
        form.dataset.submitted = "true"
      }, { once: true })
    JS

    click_button choice

    assert_field "message_content", with: choice
    assert_selector "#new_message[data-submitted='true']"
  end
end
