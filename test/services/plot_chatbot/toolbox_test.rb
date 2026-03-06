require "test_helper"

describe PlotChatbot::Toolbox do
  let(:owner) { FactoryBot.create(:user) }
  let(:other_user) { FactoryBot.create(:user) }
  let(:plot) { FactoryBot.create(:plot, user: owner, scenes_count: 2) }

  let(:plot_element_element) { FactoryBot.create(:element, :with_revision, user: owner, name: "主人公") }
  let(:candidate_element) { FactoryBot.create(:element, :with_revision, user: other_user, name: "探偵") }

  before do
    FactoryBot.create(:plot_element, plot:, element: plot_element_element, summary: nil, secrets: "秘密")
    candidate_element
  end

  it "returns plot-focused tools and a status-aware system prompt" do
    toolbox = PlotChatbot::Toolbox.new(user: owner, plot_id: plot.id)

    _(toolbox.tools.map(&:class)).must_include PlotChatbot::ListPlotElementsTool
    _(toolbox.system_prompt).must_include("plot_id: #{plot.id}")
    _(toolbox.system_prompt).must_include("要素数")
  end

  it "lists, adds, and updates plot elements" do
    toolbox = PlotChatbot::Toolbox.new(user: owner, plot_id: plot.id)

    list_tool = toolbox.tools.find { |tool| tool.is_a?(PlotChatbot::ListPlotElementsTool) }
    list_payload = JSON.parse(list_tool.execute)
    _(list_payload["status"]).must_equal("ok")
    _(list_payload["elements"].size).must_equal(1)

    add_tool = toolbox.tools.find { |tool| tool.is_a?(PlotChatbot::AddPlotElementTool) }
    add_payload = JSON.parse(add_tool.execute(element_id: candidate_element.id, summary: "相棒", secrets: "正体は不明"))
    _(add_payload["status"]).must_equal("ok")

    update_tool = toolbox.tools.find { |tool| tool.is_a?(PlotChatbot::UpdatePlotElementTool) }
    target = plot.plot_elements.find_by!(element_id: candidate_element.id)
    update_payload = JSON.parse(update_tool.execute(plot_element_id: target.id, summary: "協力者"))
    _(update_payload["status"]).must_equal("ok")
    _(target.reload.summary).must_equal("協力者")
  end

  it "searches elements outside the plot and manages scenes" do
    toolbox = PlotChatbot::Toolbox.new(user: owner, plot_id: plot.id)

    search_tool = toolbox.tools.find { |tool| tool.is_a?(PlotChatbot::SearchElementsTool) }
    search_payload = JSON.parse(search_tool.execute(query: "探偵", limit: 5))
    found_names = search_payload.fetch("elements").map { |element| element.fetch("name") }
    _(found_names).must_include("探偵")

    list_scenes_tool = toolbox.tools.find { |tool| tool.is_a?(PlotChatbot::ListScenesTool) }
    scenes_payload = JSON.parse(list_scenes_tool.execute)
    _(scenes_payload["status"]).must_equal("ok")
    _(scenes_payload.fetch("scenes").size).must_equal(2)

    add_scene_tool = toolbox.tools.find { |tool| tool.is_a?(PlotChatbot::AddSceneTool) }
    add_scene_payload = JSON.parse(add_scene_tool.execute(text: "次のシーン"))
    _(add_scene_payload["status"]).must_equal("ok")

    update_scene_tool = toolbox.tools.find { |tool| tool.is_a?(PlotChatbot::UpdateSceneTool) }
    link_id = add_scene_payload.dig("scene", "link_id")
    update_scene_payload = JSON.parse(update_scene_tool.execute(link_id:, text: "更新後シーン"))
    _(update_scene_payload["status"]).must_equal("ok")
  end

  it "returns halt payload for present_choices" do
    toolbox = PlotChatbot::Toolbox.new(user: owner, plot_id: plot.id)
    choices_tool = toolbox.tools.find { |tool| tool.is_a?(PlotChatbot::PresentChoicesTool) }

    result = choices_tool.execute(prompt: "どれにしますか?", choices: [ "A", "B", "A" ])

    _(result).must_be_kind_of(RubyLLM::Tool::Halt)
    payload = JSON.parse(result.content)
    _(payload["type"]).must_equal("choices")
    _(payload["choices"]).must_equal([ "A", "B" ])
  end
end
