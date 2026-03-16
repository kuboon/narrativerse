require "test_helper"

describe PlotWriter::McpPrompts::LatestPlotPrompt do
  it "returns the latest plot for the user" do
    user = FactoryBot.create(:user)
    old_plot = FactoryBot.create(:plot, user:, title: "古いプロット")
    new_plot = FactoryBot.create(:plot, user:, title: "新しいプロット")

    result = PlotWriter::McpPrompts::LatestPlotPrompt.template({}, server_context: { user_id: user.id })

    _(result.description).must_equal "最新プロット"
    message = result.messages.first
    payload = JSON.parse(message.content.text, symbolize_names: true)
    _(payload[:id]).must_equal new_plot.id
    _(payload[:id]).wont_equal old_plot.id
    _(payload[:title]).must_equal "新しいプロット"
  end

  it "returns an error when user does not exist" do
    result = PlotWriter::McpPrompts::LatestPlotPrompt.template({}, server_context: { user_id: -1 })

    _(result.description).must_equal "エラー"
    _(result.messages.first.content.text).must_equal "ユーザーが見つかりません。"
  end
end
