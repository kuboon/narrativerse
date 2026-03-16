# frozen_string_literal: true

module PlotWriter
  class Agent < RubyLLM::Agent
    # chat_model Chat
    inputs :plot, :scene_text

    instructions

    schema do
      string :question, description: "ユーザーに対する質問。ユーザーはこのプロンプトを見て、choicesの中から選択肢を選びます。"
      array :choices, of: :string, description: "ユーザーに提示する選択肢のリスト。ユーザーはこの中から選ぶことができます。"
    end

    tools do
      user = chat.user
      [
        Tools::AddSceneTool.new(user:, plot:),
        Tools::UpdateSceneTool.new(user:, plot:),
        Tools::AddPlotElementTool.new(user:, plot:),
        Tools::UpdatePlotElementTool.new(user:, plot:),
        Tools::SearchElementsTool.new(user:, plot:),
        Tools::ListScenesTool.new(user:, plot:)
      ]
    end
  end
end
