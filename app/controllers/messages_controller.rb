class MessagesController < ApplicationController
  include ActionController::Live

  STREAMING_ID = "message_streaming".freeze

  before_action :require_login
  before_action :set_chat

  def create
    return head :unprocessable_entity if content.blank?

    plot = Plot.find(params.dig(:message, :plot_id))

    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["Last-Modified"] = Time.now.httpdate
    response.headers["X-Accel-Buffering"] = "no"

    sse = ActionController::Live::SSE.new(response.stream)
    begin
      stream_reply(sse, plot)
    rescue ActionController::Live::ClientDisconnected
      Rails.logger.info "MessagesController#create: client disconnected"
    rescue => e
      Rails.logger.error "MessagesController#create: #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}"
      sse.write(turbo_stream.remove(STREAMING_ID))
    ensure
      sse.close
    end
  end

  private

  def set_chat
    @chat = current_user.chat || current_user.chats.create!
  end

  def content
    params.dig(:message, :content)
  end

  def stream_reply(sse, plot)
    agent = PlotWriter::Agent.new(chat: @chat, user: current_user, plot:, persist_instructions: false)

    user_message = agent.add_message(role: :user, content:)
    sse.write(turbo_stream.append("messages", user_message))

    streaming = false
    agent.after_message do
      sse.write(turbo_stream.remove(STREAMING_ID)) if streaming
      streaming = false
      sse.write(turbo_stream.append("messages", @chat.messages.order(:id).last))
    end

    agent.complete do |chunk|
      next if chunk.content.blank?

      unless streaming
        sse.write(turbo_stream.append("messages", partial: "messages/streaming"))
        streaming = true
      end
      sse.write(turbo_stream.append("#{STREAMING_ID}_content", ERB::Util.html_escape(chunk.content)))
    end
  end

  def turbo_stream
    view_context.turbo_stream
  end
end
