# frozen_string_literal: true

require "test_helper"

class MessagePresenterTest < ActiveSupport::TestCase
  extend Minitest::Spec::DSL

  # -- helpers --------------------------------------------------------------

  def new_message(attrs = {})
    user = create(:user)
    chat = create(:chat, user:)
    chat.messages.create!({ role: "assistant", content: "" }.merge(attrs))
  end

  # -- kind -----------------------------------------------------------------

  it "regular assistant message is :regular kind" do
    msg = new_message(role: "assistant", content: "こんにちは！")
    p = MessagePresenter.new(msg)
    _(p.kind).must_equal :regular
    _(p.regular?).must_equal true
    _(p.thinking?).must_equal false
    _(p.choice?).must_equal false
  end

  it "user message is :regular kind" do
    msg = new_message(role: "user", content: "テスト")
    p = MessagePresenter.new(msg)
    _(p.kind).must_equal :regular
  end

  it "system message is :thinking kind" do
    msg = new_message(role: "system", content: "system prompt")
    p = MessagePresenter.new(msg)
    _(p.kind).must_equal :thinking
    _(p.thinking?).must_equal true
  end

  it "assistant message with thinking_text is :thinking kind" do
    msg = new_message(role: "assistant", content: "回答", thinking_text: "思考中...")
    p = MessagePresenter.new(msg)
    _(p.kind).must_equal :thinking
  end

  it "choice assistant message is :choice kind" do
    payload = { type: "choices", prompt: "どうしますか？", choices: [ "A", "B" ] }.to_json
    msg = new_message(role: "assistant", content: payload)
    p = MessagePresenter.new(msg)
    _(p.kind).must_equal :choice
    _(p.choice?).must_equal true
  end

  # -- speaker / placement --------------------------------------------------

  it "user message has correct speaker and placement" do
    msg = new_message(role: "user", content: "hi")
    p = MessagePresenter.new(msg)
    _(p.speaker_name).must_equal "あなた"
    _(p.placement).must_equal "chat-end"
    _(p.bubble_color).must_equal ""
  end

  it "assistant message has correct speaker and placement" do
    msg = new_message(role: "assistant", content: "hi")
    p = MessagePresenter.new(msg)
    _(p.speaker_name).must_equal "AI"
    _(p.placement).must_equal "chat-start"
    _(p.bubble_color).must_equal "chat-bubble-neutral"
  end

  # -- status_label ---------------------------------------------------------

  it "tool_call message status_label is 'アクションを実行中'" do
    msg = new_message(role: "assistant", content: "")
    msg.tool_calls.create!(name: "plot_chatbot--add_scene", tool_call_id: "tc1", arguments: { text: "本文" })
    p = MessagePresenter.new(msg.reload)
    _(p.status_label).must_equal "アクションを実行中"
  end

  it "system message status_label is 'システム設定'" do
    msg = new_message(role: "system", content: "prompt")
    p = MessagePresenter.new(msg)
    _(p.status_label).must_equal "システム設定"
  end

  it "thinking_text message status_label is '考え中'" do
    msg = new_message(role: "assistant", content: "結果", thinking_text: "思考テキスト")
    p = MessagePresenter.new(msg)
    _(p.status_label).must_equal "考え中"
  end

  # -- tool_names_label -----------------------------------------------------

  it "returns nil for non-tool_call messages" do
    msg = new_message(role: "assistant", content: "普通のメッセージ")
    p = MessagePresenter.new(msg)
    _(p.tool_names_label).must_be_nil
  end

  it "returns human-readable tool names for tool_call message" do
    msg = new_message(role: "assistant", content: "")
    msg.tool_calls.create!(name: "plot_chatbot--add_scene", tool_call_id: "tc2", arguments: { text: "テスト" })
    p = MessagePresenter.new(msg.reload)
    _(p.tool_names_label).must_equal "シーンの追加"
  end

  # -- tool_result_summary --------------------------------------------------

  it "returns nil for non-tool_result messages" do
    msg = new_message(role: "assistant", content: "普通")
    p = MessagePresenter.new(msg)
    _(p.tool_result_summary).must_be_nil
  end

  it "returns Japanese completion summary for known tool via tool result" do
    user = create(:user)
    chat = create(:chat, user:)

    # Create an assistant message with a known tool call
    tc_msg = chat.messages.create!(role: "assistant", content: "")
    tc = tc_msg.tool_calls.create!(
      name: "plot_chatbot--add_scene",
      tool_call_id: "tc_#{SecureRandom.uuid}",
      arguments: { text: "新しいシーン" }
    )

    # Create the tool result message (role: "tool") linked to that tool_call
    result_msg = chat.messages.create!(role: "tool", content: '{"status":"ok"}', tool_call_id: tc.id)
    p = MessagePresenter.new(result_msg.reload)
    _(p.kind).must_equal :thinking
    _(p.status_label).must_equal "アクション完了"
    _(p.tool_result_summary).must_equal "シーンを追加しました"
  end

  it "returns '○○を実行しました' for unknown tool names" do
    user = create(:user)
    chat = create(:chat, user:)

    # Create an assistant message with a tool call for an unknown tool
    tc_msg = chat.messages.create!(role: "assistant", content: "")
    tc = tc_msg.tool_calls.create!(
      name: "my_plugin--do_something",
      tool_call_id: "tc_unknown_#{SecureRandom.hex(4)}",
      arguments: {}
    )

    # Create the tool result referencing the tool_calls.id (integer FK)
    result_msg = chat.messages.create!(role: "tool", content: "ok", tool_call_id: tc.id)
    p = MessagePresenter.new(result_msg.reload)
    _(p.tool_result_summary).must_match(/実行しました/)
  end
end
