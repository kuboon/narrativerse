# frozen_string_literal: true

module PlotChatbot
  class Agent < RubyLLM::Agent
    chat_model Chat
    inputs :plot_id, :scene_id

    instructions do
      current_plot_id = respond_to?(:plot_id) ? plot_id : nil
      current_scene_id = respond_to?(:scene_id) ? scene_id : nil

      plot = current_plot_id.present? ? Plot.find_by(id: current_plot_id) : nil
      PromptBuilder.new(plot:, scene_id: current_scene_id).build
    end

    tools do
      current_plot_id = respond_to?(:plot_id) ? plot_id : nil
      plot = current_plot_id.present? ? Plot.find_by(id: current_plot_id) : nil
      next [] unless plot

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
