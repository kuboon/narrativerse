require "test_helper"

describe PlotWriter::McpTools do
  let(:user) { FactoryBot.create(:user) }
  let(:plot) { FactoryBot.create(:plot, user:) }

  def payload(response)
    text = response.content.first[:text] || response.content.first["text"]
    JSON.parse(text, symbolize_names: true)
  end

  it "returns an error when server context is invalid" do
    response = PlotWriter::McpTools::CrudSceneTool.call(text: "本文", server_context: { plot_id: plot.id })
    body = payload(response)

    _(response.error?).must_equal true
    _(body[:status]).must_equal "error"
    _(body[:message]).must_equal "ユーザーが見つかりません。"
  end

  it "delegates search_elements to existing tool logic" do
    linked_element = FactoryBot.create(:element, :with_revision, user:, name: "既存要素")
    FactoryBot.create(:plot_element, plot:, element: linked_element, element_revision: linked_element.latest_revision)

    candidate = FactoryBot.create(:element, :with_revision, user:, name: "候補キャラ", element_type: "Character")

    response = PlotWriter::McpTools::SearchElementsTool.call(
      query: "候補",
      limit: 5,
      server_context: { user_id: user.id, plot_id: plot.id }
    )
    body = payload(response)

    _(response.error?).must_equal false
    _(body[:status]).must_equal "ok"
    _(body[:elements].map { |element| element[:id] }).must_include candidate.id
    _(body[:elements].map { |element| element[:id] }).wont_include linked_element.id
  end

  it "delegates crud_element to existing tool logic" do
    element = FactoryBot.create(:element, :with_revision, user:, name: "追加要素")

    response = PlotWriter::McpTools::CrudElementTool.call(
      element_id: element.id,
      summary: "主人公の相棒",
      server_context: { user_id: user.id, plot_id: plot.id }
    )
    body = payload(response)

    _(response.error?).must_equal false
    _(body[:status]).must_equal "ok"
    _(plot.plot_elements.find_by(element_id: element.id)&.summary).must_equal "主人公の相棒"
  end

  it "delegates crud_scene to existing tool logic" do
    link = plot.plot_scene_links.first

    response = PlotWriter::McpTools::CrudSceneTool.call(
      scene_id: link.scene_id,
      text: "更新した本文",
      server_context: { user_id: user.id, plot_id: plot.id }
    )
    body = payload(response)

    _(response.error?).must_equal false
    _(body[:status]).must_equal "ok"
    _(link.scene.reload.text).must_equal "更新した本文"
  end
end
