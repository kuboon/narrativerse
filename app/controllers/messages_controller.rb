class MessagesController < ApplicationController
  include ActionController::Live

  before_action :require_login
  before_action :set_chat

  def create
    return head :unprocessable_entity unless content.present?

    # Set up SSE response headers
    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Last-Modified"] = Time.now.httpdate
    response.headers["Cache-Control"] = "no-cache"
    response.headers["X-Accel-Buffering"] = "no"

    sse = ActionController::Live::SSE.new(response.stream, event: "turbo-stream")
    utf8_buffer = Utf8Buffer.new

    begin
      plot_id = context_plot_id
      @plot = Plot.find(plot_id)

      # 1. Save and stream user message
      @user_message = @chat.messages.create!(role: "user", content: content)
      stream_turbo_append(sse, "messages", @user_message)

      # 2. Setup Agent
      agent = PlotWriter::Agent.chat(user: current_user, plot: @plot)
      @chat.messages.each { |msg| agent.add_message(msg.to_llm) }

      # 3. Create and stream empty assistant message container
      @assistant_message = @chat.messages.create!(role: "assistant", chat: @chat)
      stream_turbo_append(sse, "messages", @assistant_message)

      # 4. Stream response chunks
      agent.on_end_message do |llm_message|
        @assistant_message.assign_message(llm_message)
        @assistant_message.save!

        # If choices are present, update the whole content area
        if @assistant_message.choice_payload.present?
          stream_turbo_replace(sse, "message_#{@assistant_message.id}_content", @assistant_message)
        end
      end

      agent.ask(content) do |chunk|
        if chunk.content.present?
          # Buffer partial UTF-8 characters
          valid_content = utf8_buffer.append(chunk.content.to_s)
          next if valid_content.empty?

          # Escape and append chunk to the specific content bubble
          escaped_content = ERB::Util.html_escape(valid_content)
          sse.write(view_context.turbo_stream.append("message_#{@assistant_message.id}_content", escaped_content))
        end
      end

    rescue => e
      Rails.logger.error "MessagesController#create SSE Error: #{e.message}\n#{e.backtrace.join("\n")}"
      # We could optionally stream an error message to the UI here
    ensure
      sse.close
    end
  end

  private

  def set_chat
    @chat = current_user.chats.first
  end

  def content
    params.dig(:message, :content)
  end

  def context_plot_id
    params.dig(:message, :plot_id).presence
  end

  def stream_turbo_append(sse, target, message)
    sse.write(view_context.turbo_stream.append(target, partial: "messages/message", locals: { message: }))
  end

  def stream_turbo_replace(sse, target, message)
    sse.write(view_context.turbo_stream.replace(target, partial: "messages/message", locals: { message: }))
  end

  # Helper to buffer split UTF-8 characters during streaming
  class Utf8Buffer
    def initialize
      @buffer = "".b
    end

    def append(chunk)
      @buffer << chunk.to_s.b
      return "" if @buffer.empty?

      # Force UTF-8 on a copy to check validity
      if @buffer.dup.force_encoding("UTF-8").valid_encoding?
        valid = @buffer.dup.force_encoding("UTF-8")
        @buffer.clear
        valid
      else
        # Find the last valid UTF-8 character boundary
        (1..3).each do |i|
          break if i >= @buffer.length
          candidate = @buffer[0...-i]
          if candidate.dup.force_encoding("UTF-8").valid_encoding?
            valid_part = candidate.dup.force_encoding("UTF-8")
            @buffer = @buffer[-i..-1]
            return valid_part
          end
        end
        "" # Still not valid, keep buffering
      end
    end
  end
end
