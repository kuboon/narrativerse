class ChatResponseJob < ApplicationJob
  def perform(chat_id, content, plot_id = nil, scene_id = nil)
    chat = Chat.find(chat_id)
    toolbox = PlotChatbot::Toolbox.new(user: chat.user, plot_id:, scene_id:)

    llm_chat = chat.with_instructions(toolbox.system_prompt, replace: true)
    llm_chat = llm_chat.with_tools(*toolbox.tools) if toolbox.tools.any?

    @current_streaming_message = nil

    response = llm_chat.ask(content) do |chunk|
      broadcast_chunk(chat, chunk)
    end

    while response.tool_calls?
      results = []
      halted_result = nil

      begin
        response.tool_calls.each do |tool_call|
          tool = toolbox.tools.find { |t| t.name == tool_call.name }
          if tool
            output = tool.execute(**tool_call.arguments.symbolize_keys)
            results << { tool_call_id: tool_call.tool_call_id, content: output }
          end
        end
      rescue PlotChatbot::Halt => e
        # If a tool (like present_choices) requested a halt,
        # we still need to record the result that caused the halt.
        current_tool_call = response.tool_calls[results.size]
        if current_tool_call
          results << { tool_call_id: current_tool_call.tool_call_id, content: e.message }
        end
        halted_result = e.message
      end

      if results.any?
        # Save results to DB so they appear in the UI
        # Reset current streaming message so chunks go to the right message
        @current_streaming_message = nil

        results.each do |res|
          # Resolve LLM string tool_call_id to integer FK of tool_calls table
          tc_record_id = ToolCall.find_by(tool_call_id: res[:tool_call_id])&.id
          chat.messages.create!(role: "tool", tool_call_id: tc_record_id, content: res[:content])
        end

        break if halted_result

        # Continue the conversation with the results
        response = llm_chat.ask(results) do |chunk|
          broadcast_chunk(chat, chunk)
        end
      else
        break
      end
    end
  rescue => e
    Rails.logger.error "ChatResponseJob Error: #{e.message}\n#{e.backtrace.join("\n")}"
    raise e
  end

  private

  def broadcast_chunk(chat, chunk)
    return if chunk.content.blank?

    # Track the current assistant message being streamed.
    # We reload only when @current_streaming_message is nil (new turn starts).
    @current_streaming_message ||= chat.messages.where(role: :assistant).last
    return unless @current_streaming_message

    @current_streaming_message.broadcast_append_chunk(chunk.content)
  end
end
