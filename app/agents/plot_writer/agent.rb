# frozen_string_literal: true

module PlotWriter
  class Agent < RubyLLM::Agent
    inputs :user, :plot, :scene_text

    instructions

    schema do
      string :question, description: "ユーザーに対する質問。ユーザーはこの質問を見て、choicesの中から選択肢を選びます。"
      array :choices, of: :string, description: "ユーザーに提示する選択肢のリスト。ユーザーはこの中から選ぶことができます。"
    end

    tools do
      [
        Tools::ForRubyLLM::CrudSceneTool.new(user:, plot:),
        Tools::ForRubyLLM::AddElementTool.new(user:, plot:),
        Tools::ForRubyLLM::UpdateElementTool.new(user:, plot:),
        Tools::ForRubyLLM::SearchElementsTool.new(user:, plot:)
      ]
    end
  end
end
