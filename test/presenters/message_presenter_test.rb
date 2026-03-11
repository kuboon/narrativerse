# frozen_string_literal: true

require "test_helper"

class MessagePresenterTest < ActiveSupport::TestCase
  extend Minitest::Spec::DSL

  # -- helpers --------------------------------------------------------------

  let(:user) { create(:user) }
  let(:chat) { create(:chat, user:) }

  def build_message(attrs = {})
    chat.messages.create!({ role: "assistant", content: "" }.merge(attrs))
  end

  def build_tool_call_message(tool_name:, arguments: {})
    msg = build_message(role: "assistant", content: "")
    msg.tool_calls.create!(
      name: tool_name,
      tool_call_id: "tc_#{SecureRandom.uuid}",
      arguments: arguments
    )
    msg.reload
  end

  def build_tool_result_message(tool_call:)
    chat.messages.create!(role: "tool", content: '{"status":"ok"}', tool_call_id: tool_call.id)
  end

  def presenter(messages)
    MessagePresenter.new(messages)
  end

  # -- entries: regular messages --------------------------------------------

  it "single user message produces one RegularEntry" do
    msg = build_message(role: "user", content: "こんにちは")
    entries = presenter([ msg ]).entries
    _(entries.size).must_equal 1
    _(entries.first).must_be_instance_of MessagePresenter::RegularEntry
    _(entries.first.message).must_equal msg
  end

  it "single assistant message produces one RegularEntry" do
    msg = build_message(role: "assistant", content: "返答です")
    entries = presenter([ msg ]).entries
    _(entries.first).must_be_instance_of MessagePresenter::RegularEntry
  end

  it "choice assistant message produces one ChoiceEntry" do
    payload = { type: "choices", prompt: "どうしますか？", choices: [ "A", "B" ] }.to_json
    msg = build_message(role: "assistant", content: payload)
    entries = presenter([ msg ]).entries
    _(entries.size).must_equal 1
    _(entries.first).must_be_instance_of MessagePresenter::ChoiceEntry
    _(entries.first.payload["choices"]).must_equal [ "A", "B" ]
  end

  # -- entries: thinking/action messages ------------------------------------

  it "system message produces no entries" do
    msg = build_message(role: "system", content: "system prompt")
    entries = presenter([ msg ]).entries
    _(entries).must_be_empty
  end

  it "tool_call message produces one ActionItem" do
    msg = build_tool_call_message(tool_name: "plot_chatbot--add_scene")
    entries = presenter([ msg ]).entries
    _(entries.size).must_equal 1
    _(entries.first).must_be_instance_of MessagePresenter::ActionItem
  end

  it "assistant message with thinking_text produces one ThinkingEntry" do
    msg = build_message(role: "assistant", content: "回答", thinking_text: "思考中...")
    entries = presenter([ msg ]).entries
    _(entries.first).must_be_instance_of MessagePresenter::ThinkingEntry
  end

  it "empty messages list produces no entries" do
    _(presenter([]).entries).must_be_empty
  end

  # -- sequence: thinking/action entries are independent --------------------

  it "consecutive thinking-kind messages are rendered as independent entries" do
    tc_msg = build_tool_call_message(tool_name: "plot_chatbot--add_scene")
    tc     = tc_msg.tool_calls.first
    result_msg = build_tool_result_message(tool_call: tc)

    entries = presenter([ tc_msg, result_msg ]).entries
    # tool_call is hidden once its result exists; only the result ActionItem shows
    _(entries.size).must_equal 1
    _(entries[0]).must_be_instance_of MessagePresenter::ActionItem
    _(entries[0].done).must_equal true
  end

  it "non-thinking message keeps full order between thinking/action entries" do
    tc_msg     = build_tool_call_message(tool_name: "plot_chatbot--add_scene")
    tc         = tc_msg.tool_calls.first
    result_msg = build_tool_result_message(tool_call: tc)
    regular    = build_message(role: "assistant", content: "まとめです")
    thinking   = build_message(role: "assistant", content: "", thinking_text: "検討中")
    tc_msg2    = build_tool_call_message(tool_name: "plot_chatbot--list_scenes")

    # tc_msg is suppressed (result exists); tc_msg2 has no result → stays
    entries = presenter([ tc_msg, result_msg, regular, thinking, tc_msg2 ]).entries
    _(entries.size).must_equal 4
    _(entries[0]).must_be_instance_of MessagePresenter::ActionItem  # tool_result
    _(entries[1]).must_be_instance_of MessagePresenter::RegularEntry
    _(entries[2]).must_be_instance_of MessagePresenter::ThinkingEntry
    _(entries[3]).must_be_instance_of MessagePresenter::ActionItem  # in-progress tc_msg2
  end

  it "thinking/action entry lead_message_id equals source message id" do
    tc_msg     = build_tool_call_message(tool_name: "plot_chatbot--add_scene")
    tc         = tc_msg.tool_calls.first
    result_msg = build_tool_result_message(tool_call: tc)
    thinking   = build_message(role: "assistant", content: "", thinking_text: "思考中")

    # tc_msg suppressed (result exists); result_msg and thinking remain
    entries = presenter([ tc_msg, result_msg, thinking ]).entries
    _(entries[0].lead_message_id).must_equal result_msg.id
    _(entries[1].lead_message_id).must_equal thinking.id
  end

  # -- ActionItem contents --------------------------------------------------

  it "tool_call action has correct status_label, detail_label, and execution_text" do
    tc_msg = build_tool_call_message(
      tool_name: "plot_chatbot--add_scene",
      arguments: { "title" => "導入", "priority" => 1 }
    )
    entry  = presenter([ tc_msg ]).entries.first
    _(entry.status_label).must_equal "アクションを実行中"
    _(entry.detail_label).must_equal "シーンの追加"
    _(entry.execution_text).must_match(/"title": "導入"/)
    _(entry.done).must_equal false
  end

  it "completed tool_call (result exists) produces no in-progress ActionItem" do
    tc_msg = build_tool_call_message(tool_name: "plot_chatbot--add_scene")
    tc     = tc_msg.tool_calls.first
    result_msg = build_tool_result_message(tool_call: tc)

    entries = presenter([ tc_msg, result_msg ]).entries
    _(entries.size).must_equal 1
    _(entries.first.done).must_equal true
  end

  it "present_choices tool_call produces no entry" do
    tc_msg = build_tool_call_message(tool_name: "plot_chatbot--present_choices")
    entries = presenter([ tc_msg ]).entries
    _(entries).must_be_empty
  end

  it "tool_result action has correct status_label, completion summary, and execution_text" do
    tc_msg = build_tool_call_message(tool_name: "plot_chatbot--add_scene")
    tc     = tc_msg.tool_calls.first
    result = build_tool_result_message(tool_call: tc)

    entry = presenter([ tc_msg, result ]).entries.last
    _(entry.status_label).must_equal "アクション完了"
    _(entry.detail_label).must_equal "シーンを追加しました"
    _(entry.execution_text).must_match(/"status": "ok"/)
    _(entry.done).must_equal true
  end

  it "system message produces no entry" do
    msg = build_message(role: "system", content: "prompt")
    _(presenter([ msg ]).entries).must_be_empty
  end

  it "thinking_text message produces ThinkingEntry with thinking text" do
    msg    = build_message(role: "assistant", content: "回答", thinking_text: "思考テキスト")
    entry  = presenter([ msg ]).entries.first
    _(entry.status_label).must_equal "考え中"
    _(entry.thinking_text).must_equal "思考テキスト"
    _(entry.done).must_equal false
  end

  it "unknown tool name falls back to '○○を実行しました'" do
    tc_msg = build_tool_call_message(tool_name: "my_plugin--do_something")
    tc     = tc_msg.tool_calls.first
    result = build_tool_result_message(tool_call: tc)

    entry = presenter([ tc_msg, result ]).entries.last
    _(entry.detail_label).must_match(/実行しました/)
  end

  # -- mixed sequence -------------------------------------------------------

  it "mixed sequence produces entries in correct order" do
    user_msg   = build_message(role: "user", content: "お願いします")
    sys_msg    = build_message(role: "system", content: "prompt")
    tc_msg     = build_tool_call_message(tool_name: "plot_chatbot--list_scenes")
    tc         = tc_msg.tool_calls.first
    result_msg = build_tool_result_message(tool_call: tc)
    reply_msg  = build_message(role: "assistant", content: "完了しました！")

    # sys_msg suppressed; tc_msg suppressed (result exists)
    entries = presenter([ user_msg, sys_msg, tc_msg, result_msg, reply_msg ]).entries
    _(entries.size).must_equal 3
    _(entries[0]).must_be_instance_of MessagePresenter::RegularEntry   # user
    _(entries[1]).must_be_instance_of MessagePresenter::ActionItem     # tool_result
    _(entries[2]).must_be_instance_of MessagePresenter::RegularEntry   # assistant reply
  end
end
