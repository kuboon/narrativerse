# frozen_string_literal: true

module PlotAgent
  class Agent < RubyLLM::Agent
    chat_model Chat
    inputs :plot, :scene

    instructions

    tools do
      user = chat.user
      [
        Tools::ListPlotElementsTool.new(user:, plot:),
        Tools::AddPlotElementTool.new(user:, plot:),
        Tools::UpdatePlotElementTool.new(user:, plot:),
        Tools::SearchElementsTool.new(user:, plot:),
        Tools::ListScenesTool.new(user:, plot:),
        Tools::AddSceneTool.new(user:, plot:),
        Tools::UpdateSceneTool.new(user:, plot:),
        Tools::PresentChoicesTool.new(user:, plot:)
      ]
    end
  end
end
