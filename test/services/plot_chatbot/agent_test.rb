require "test_helper"

describe PlotAgent::Agent do
  let(:owner) { FactoryBot.create(:user) }
  let(:other_user) { FactoryBot.create(:user) }
  let(:plot) { FactoryBot.create(:plot, user: owner, scenes_count: 2) }
  let(:chat) { FactoryBot.create(:chat, user: owner) }

  let(:plot_element_element) { FactoryBot.create(:element, :with_revision, user: owner, name: "主人公") }
  let(:candidate_element) { FactoryBot.create(:element, :with_revision, user: other_user, name: "探偵") }

  before do
    FactoryBot.create(:plot_element, plot:, element: plot_element_element, summary: nil, secrets: "秘密")
    candidate_element
  end

  it "applies plot-aware instructions and tools" do
    PlotAgent::Agent.new(chat:, plot:, persist_instructions: false)

    llm_chat = chat.to_llm
    system_message = llm_chat.messages.find { |message| message.role == :system }

    _(system_message).wont_be_nil
    _(system_message.content).must_include("plot_id: #{plot.id}")
    _(system_message.content).must_include("フォーカス scene_id: 123")

    tool_classes = llm_chat.tools.values.map(&:class)
    _(tool_classes).must_include PlotAgent::Tools::ListPlotElementsTool
    _(tool_classes).must_include PlotAgent::Tools::PresentChoicesTool
  end

  it "uses generic instructions and no tools without plot context" do
    PlotAgent::Agent.new(chat:, persist_instructions: false)

    llm_chat = chat.to_llm
    system_message = llm_chat.messages.find { |message| message.role == :system }

    _(system_message.content).must_include("創作アシスタント")
    _(llm_chat.tools).must_be_empty
  end

  it "executes configured tools in rails mode" do
    PlotAgent::Agent.new(chat:, plot_id: plot.id, persist_instructions: false)

    llm_tools = chat.to_llm.tools.values

    list_tool = llm_tools.find { |tool| tool.is_a?(PlotAgent::Tools::ListPlotElementsTool) }
    list_payload = JSON.parse(list_tool.execute)
    _(list_payload["status"]).must_equal("ok")

    add_tool = llm_tools.find { |tool| tool.is_a?(PlotAgent::Tools::AddPlotElementTool) }
    add_payload = JSON.parse(add_tool.execute(element_id: candidate_element.id, summary: "相棒", secrets: "正体は不明"))
    _(add_payload["status"]).must_equal("ok")

    update_tool = llm_tools.find { |tool| tool.is_a?(PlotAgent::Tools::UpdatePlotElementTool) }
    target = plot.plot_elements.find_by!(element_id: candidate_element.id)
    update_payload = JSON.parse(update_tool.execute(plot_element_id: target.id, summary: "協力者"))
    _(update_payload["status"]).must_equal("ok")

    search_tool = llm_tools.find { |tool| tool.is_a?(PlotAgent::Tools::SearchElementsTool) }
    search_payload = JSON.parse(search_tool.execute(query: "探偵", limit: 5))
    found_names = search_payload.fetch("elements").map { |element| element.fetch("name") }
    _(found_names).must_include("探偵")

    list_scenes_tool = llm_tools.find { |tool| tool.is_a?(PlotAgent::Tools::ListScenesTool) }
    scenes_payload = JSON.parse(list_scenes_tool.execute)
    _(scenes_payload["status"]).must_equal("ok")
    _(scenes_payload.fetch("scenes").size).must_equal(2)

    add_scene_tool = llm_tools.find { |tool| tool.is_a?(PlotAgent::Tools::AddSceneTool) }
    add_scene_payload = JSON.parse(add_scene_tool.execute(text: "次のシーン"))
    _(add_scene_payload["status"]).must_equal("ok")

    update_scene_tool = llm_tools.find { |tool| tool.is_a?(PlotAgent::Tools::UpdateSceneTool) }
    link_id = add_scene_payload["link_id"]
    update_scene_payload = JSON.parse(update_scene_tool.execute(link_id:, text: "更新後シーン"))
    _(update_scene_payload["status"]).must_equal("ok")

    choices_tool = llm_tools.find { |tool| tool.is_a?(PlotAgent::Tools::PresentChoicesTool) }
    result = choices_tool.execute(prompt: "どれにしますか?", choices: [ "A", "B", "A" ])
    _(result).must_be_kind_of RubyLLM::Tool::Halt

    payload = JSON.parse(result.content)
    _(payload["type"]).must_equal("choices")
    _(payload["choices"]).must_equal([ "A", "B" ])
  end
end
