class ChatResponseJob < ApplicationJob
  def perform(chat_id, content:, plot_id:, scene_id:)
    chat = Chat.find(chat_id)
    plot = Plot.find(plot_id)
    user = chat.user

    agent = PlotWriter::Agent.chat(user:, plot:)
    # chat.messages.build(role: "user", content: content) if content.present?
    chat.messages.each { |msg| agent.add_message(msg.to_llm) }
    agent.on_end_message do |message|
      m = chat.messages.build
      m.assign_message(message)
      m.save!
    end

    content ? agent.ask(content) : agent.complete
  rescue => e
    Rails.logger.error "ChatResponseJob Error: #{e.message}\n#{e.backtrace.join("\n")}"
    raise e
  end
end
