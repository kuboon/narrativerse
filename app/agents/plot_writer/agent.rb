# frozen_string_literal: true

module PlotWriter
  class Agent < RubyLLM::Agent
    chat_model Chat
    inputs :plot, :scene_text

    instructions

    schema do
      string :question, description: "ユーザーに対する質問。ユーザーはこの質問を見て、choicesの中から選択肢を選びます。"
      array :choices, of: :string, description: "ユーザーに提示する選択肢のリスト。ユーザーはこの中から選ぶことができます。"
    end

    tools do
      user = chat.user
      [
        Tools::CrudSceneTool.new(user:, plot:),
        Tools::CrudElementTool.new(user:, plot:),
        Tools::SearchElementsTool.new(user:, plot:)
      ]
    end
  end
end
