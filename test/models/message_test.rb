require "test_helper"

class MessageTest < ActiveSupport::TestCase
  extend Minitest::Spec::DSL

  # -- choice_payload: LLM がツールコールで選択肢を返すフロー ----------------

  it "creates choice message via present_choices tool call through ask" do
    user = create(:user)
    plot = create(:plot, user:, scenes_count: 1)
    chat = create(:chat, user:)
    agent = PlotChatbot::Agent.new(chat:, plot_id: plot.id, persist_instructions: false)

    tool_call_response = RubyLLM::StubProvider.bedrock_tool_call(
      tool_use_id: "tc_choice_1",
      name: "plot_chatbot--present_choices",
      input: { "prompt" => "どうしますか？", "choices" => [ "A", "B", "C" ] }
    )

    RubyLLM::StubProvider.stub_chat(tool_call_response) do
      agent.ask("何か提案して")
    end

    tool_result_msg = chat.messages.where(role: "tool").last
    _(tool_result_msg).wont_be_nil
    _(tool_result_msg.choice_message?).must_equal true

    payload = tool_result_msg.choice_payload
    _(payload["prompt"]).must_equal "どうしますか？"
    _(payload["choices"]).must_equal [ "A", "B", "C" ]
  end

  it "deduplicates choices through present_choices tool" do
    user = create(:user)
    plot = create(:plot, user:, scenes_count: 1)
    chat = create(:chat, user:)
    agent = PlotChatbot::Agent.new(chat:, plot_id: plot.id, persist_instructions: false)

    tool_call_response = RubyLLM::StubProvider.bedrock_tool_call(
      tool_use_id: "tc_dedup",
      name: "plot_chatbot--present_choices",
      input: { "prompt" => "選んで", "choices" => [ "A", "B", "A", "" ] }
    )

    RubyLLM::StubProvider.stub_chat(tool_call_response) do
      agent.ask("選択肢を出して")
    end

    payload = chat.messages.where(role: "tool").last.choice_payload
    _(payload["choices"]).must_equal [ "A", "B" ]
  end

  # -- choice_payload: assistant メッセージ内の JSON パース ------------------

  it "parses choice payload from assistant json" do
    user = create(:user)
    chat = create(:chat, user:)

    message = chat.messages.create!(
      role: "assistant",
      content: { type: "choices", prompt: "何から始めましょうか？", choices: [ "A", "B", "A", "" ] }.to_json
    )

    payload = message.choice_payload

    _(message.choice_message?).must_equal true
    _(message.thinking_message?).must_equal false
    _(payload["prompt"]).must_equal "何から始めましょうか？"
    _(payload["choices"]).must_equal [ "A", "B" ]
  end

  it "parses choice payload from markdown code fence" do
    user = create(:user)
    chat = create(:chat, user:)

    message = chat.messages.create!(
      role: "assistant",
      content: <<~TEXT
        提案します。
        ```json
        {"type":"choices","prompt":"追加したい要素を選んでください。","choices":["1) 主人公","2) 仲間"]}
        ```
      TEXT
    )

    _(message.choice_message?).must_equal true
    payload = message.choice_payload
    _(payload["prompt"]).must_equal "追加したい要素を選んでください。"
    _(payload["choices"]).must_equal [ "1) 主人公", "2) 仲間" ]
  end

  it "parses choice payload from embedded json in text" do
    user = create(:user)
    chat = create(:chat, user:)

    message = chat.messages.create!(
      role: "assistant",
      content: '以下を表示します: {"type":"choices","prompt":"選んでください","choices":["A","B"]}'
    )

    _(message.choice_message?).must_equal true
    payload = message.choice_payload
    _(payload["prompt"]).must_equal "選んでください"
    _(payload["choices"]).must_equal [ "A", "B" ]
  end

  # -- thinking_message? ---------------------------------------------------

  it "marks system and tool-call messages as thinking" do
    user = create(:user)
    chat = create(:chat, user:)

    system_message = chat.messages.create!(role: "system", content: "system prompt")
    _(system_message.thinking_message?).must_equal true

    tool_call_message = chat.messages.create!(role: "assistant", content: "")
    tool_call_message.tool_calls.create!(
      name: "search_elements",
      tool_call_id: "tool-call-2",
      arguments: { query: "探偵" }
    )

    _(tool_call_message.reload.thinking_message?).must_equal true

    thinking_text_message = chat.messages.create!(role: "assistant", content: "Final answer", thinking_text: "Reasoning...")
    _(thinking_text_message.thinking_message?).must_equal true
  end
end
