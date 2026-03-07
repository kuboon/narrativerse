class ChatResponseJob < ApplicationJob
  def perform(chat_id, content, plot_id = nil, scene_id = nil)
    chat = Chat.find(chat_id)
    toolbox = PlotChatbot::Toolbox.new(user: chat.user, plot_id:, scene_id:)

    llm_chat = chat.with_instructions(toolbox.system_prompt, replace: true)
    llm_chat = llm_chat.with_tools(*toolbox.tools) if toolbox.tools.any?

    llm_chat.ask(content) do |chunk|
      next if chunk.content.blank?

      chat.messages.where(role: :assistant).last&.broadcast_append_chunk(chunk.content)
    end
  rescue => e
    Rails.logger.error "ChatResponseJob Error: #{e.message}\n#{e.backtrace.join("\n")}"
    raise e
  end
end
