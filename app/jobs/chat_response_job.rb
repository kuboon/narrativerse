class ChatResponseJob < ApplicationJob
  def perform(chat_id, content:, plot_id:, scene_id:)
    plot = Plot.find(plot_id)
    chat = PlotWriter::Agent.find(chat_id, plot:)

    chat.ask(content) do |chunk|
      next if chunk.content.blank?

      chat.messages.where(role: :assistant).last&.broadcast_append_chunk(chunk.content)
    end
  rescue => e
    Rails.logger.error "ChatResponseJob Error: #{e.message}\n#{e.backtrace.join("\n")}"
    raise e
  end
end
