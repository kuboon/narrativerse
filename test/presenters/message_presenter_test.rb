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

  def build_tool_call_message(tool_name:)
    msg = build_message(role: "assistant", content: "")
    msg.tool_calls.create!(
      name: tool_name,
      tool_call_id: "tc_#{SecureRandom.uuid}",
      arguments: {}
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

  # -- entries: thinking messages -------------------------------------------

  it "system message produces one ThinkingEntry" do
    msg = build_message(role: "system", content: "system prompt")
    entries = presenter([ msg ]).entries
    _(entries.size).must_equal 1
    _(entries.first).must_be_instance_of MessagePresenter::ThinkingEntry
  end

  it "assistant message with thinking_text produces ThinkingEntry" do
    msg = build_message(role: "assistant", content: "回答", thinking_text: "思考中...")
    entries = presenter([ msg ]).entries
    _(entries.first).must_be_instance_of MessagePresenter::ThinkingEntry
  end

  it "empty messages list produces no entries" do
    _(presenter([]).entries).must_be_empty
  end

  # -- grouping: consecutive thinking messages are merged -------------------

  it "consecutive thinking messages are collapsed into a single ThinkingEntry" do
    tc_msg = build_tool_call_message(tool_name: "plot_chatbot--add_scene")
    tc     = tc_msg.tool_calls.first
    result_msg = build_tool_result_message(tool_call: tc)

    entries = presenter([ tc_msg, result_msg ]).entries
    _(entries.size).must_equal 1
    entry = entries.first
    _(entry).must_be_instance_of MessagePresenter::ThinkingEntry
    _(entry.actions.size).must_equal 2
  end

  it "non-thinking message between thinking messages breaks the group" do
    tc_msg     = build_tool_call_message(tool_name: "plot_chatbot--add_scene")
    tc         = tc_msg.tool_calls.first
    result_msg = build_tool_result_message(tool_call: tc)
    regular    = build_message(role: "assistant", content: "まとめです")
    tc_msg2    = build_tool_call_message(tool_name: "plot_chatbot--list_scenes")

    entries = presenter([ tc_msg, result_msg, regular, tc_msg2 ]).entries
    _(entries.size).must_equal 3
    _(entries[0]).must_be_instance_of MessagePresenter::ThinkingEntry
    _(entries[0].actions.size).must_equal 2
    _(entries[1]).must_be_instance_of MessagePresenter::RegularEntry
    _(entries[2]).must_be_instance_of MessagePresenter::ThinkingEntry
    _(entries[2].actions.size).must_equal 1
  end

  it "ThinkingEntry lead_message_id is the first message id in the group" do
    tc_msg     = build_tool_call_message(tool_name: "plot_chatbot--add_scene")
    tc         = tc_msg.tool_calls.first
    result_msg = build_tool_result_message(tool_call: tc)

    entry = presenter([ tc_msg, result_msg ]).entries.first
    _(entry.lead_message_id).must_equal tc_msg.id
  end

  # -- ActionItem contents --------------------------------------------------

  it "tool_call action has correct status_label and detail_label" do
    tc_msg = build_tool_call_message(tool_name: "plot_chatbot--add_scene")
    entry  = presenter([ tc_msg ]).entries.first
    action = entry.actions.first
    _(action.status_label).must_equal "アクションを実行中"
    _(action.detail_label).must_equal "シーンの追加"
    _(action.done).must_equal false
  end

  it "tool_result action has correct status_label, completion summary, and done=true" do
    tc_msg = build_tool_call_message(tool_name: "plot_chatbot--add_scene")
    tc     = tc_msg.tool_calls.first
    result = build_tool_result_message(tool_call: tc)

    entry  = presenter([ tc_msg, result ]).entries.first
    action = entry.actions.last
    _(action.status_label).must_equal "アクション完了"
    _(action.detail_label).must_equal "シーンを追加しました"
    _(action.done).must_equal true
  end

  it "system message action has 'システム設定' label and done=true" do
    msg    = build_message(role: "system", content: "prompt")
    entry  = presenter([ msg ]).entries.first
    action = entry.actions.first
    _(action.status_label).must_equal "システム設定"
    _(action.done).must_equal true
  end

  it "thinking_text message action has '考え中' label and thinking_text" do
    msg    = build_message(role: "assistant", content: "回答", thinking_text: "思考テキスト")
    entry  = presenter([ msg ]).entries.first
    action = entry.actions.first
    _(action.status_label).must_equal "考え中"
    _(action.thinking_text).must_equal "思考テキスト"
    _(action.done).must_equal false
  end

  it "unknown tool name falls back to '○○を実行しました'" do
    tc_msg = build_tool_call_message(tool_name: "my_plugin--do_something")
    tc     = tc_msg.tool_calls.first
    result = build_tool_result_message(tool_call: tc)

    entry  = presenter([ tc_msg, result ]).entries.first
    action = entry.actions.last
    _(action.detail_label).must_match(/実行しました/)
  end

  # -- mixed sequence -------------------------------------------------------

  it "mixed sequence produces entries in correct order" do
    user_msg   = build_message(role: "user", content: "お願いします")
    sys_msg    = build_message(role: "system", content: "prompt")
    tc_msg     = build_tool_call_message(tool_name: "plot_chatbot--list_scenes")
    tc         = tc_msg.tool_calls.first
    result_msg = build_tool_result_message(tool_call: tc)
    reply_msg  = build_message(role: "assistant", content: "完了しました！")

    entries = presenter([ user_msg, sys_msg, tc_msg, result_msg, reply_msg ]).entries
    _(entries.size).must_equal 3
    _(entries[0]).must_be_instance_of MessagePresenter::RegularEntry   # user
    _(entries[1]).must_be_instance_of MessagePresenter::ThinkingEntry  # system + tool_call + tool_result
    _(entries[1].actions.size).must_equal 3
    _(entries[2]).must_be_instance_of MessagePresenter::RegularEntry   # assistant reply
  end
end
