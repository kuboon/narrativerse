class Message < ApplicationRecord
  acts_as_message
  has_many_attached :attachments
  broadcasts_to :chat

  def broadcast_append_chunk(content)
    broadcast_append_to "chat_#{chat_id}",
      target: "message_#{id}_content",
      content: ERB::Util.html_escape(content.to_s)
  end

  def choice_payload
    return if content.present?

    payload = normalize_choice_payload(content_raw)
    return unless payload.is_a?(Hash)

    question = payload["question"].presence
    choices = Array(payload["choices"]).filter_map { |choice| choice.to_s.strip.presence }
    return if question.blank? || choices.empty?

    {
      "question" => question,
      "choices" => choices
    }
  end

  def assign_message(message)
    return unless message

    tool_call_id = find_tool_call_id(message.tool_call_id) if message.tool_call_id

    content_text, attachments_to_persist, content_raw = prepare_content_for_storage(message.content)

    attrs = {
      tool_call_id:,
      role: message.role,
      content: content_text,
      input_tokens: message.input_tokens,
      output_tokens: message.output_tokens,
      cached_tokens: message.cached_tokens,
      cache_creation_tokens: message.cache_creation_tokens,
      thinking_text: message.thinking&.text,
      thinking_signature: message.thinking&.signature,
      thinking_tokens: message.thinking_tokens
    }

    # if tool_call_id
    #   parent_tool_call_assoc = @message.class.reflect_on_association(:parent_tool_call)
    #   attrs[parent_tool_call_assoc.foreign_key] = tool_call_id
    # end

    @message.assign_attributes(attrs)
    @message.content_raw = content_raw if @message.respond_to?(:content_raw=)

    # persist_content(@message, attachments_to_persist) if attachments_to_persist
    # persist_tool_calls(message.tool_calls) if message.tool_calls.present?
  end
  private

  def normalize_choice_payload(raw)
    case raw
    when Hash
      raw.stringify_keys
    when String
      parse_choice_payload(raw)
    when Array
      normalize_choice_payload(extract_choice_payload_value(raw))
    end
  end

  def extract_choice_payload_value(raw)
    return raw.last if raw.length == 2 && raw.first == "content_raw"
    return raw.first if raw.one?

    nil
  end

  def parse_choice_payload(raw)
    JSON.parse(raw).stringify_keys
  rescue JSON::ParserError, TypeError
    nil
  end

  def prepare_content_for_storage(content)
    attachments = nil
    content_raw = nil
    content_text = content

    case content
    when RubyLLM::Content::Raw
      content_raw = content.value
      content_text = nil
    when RubyLLM::Content
      attachments = content.attachments if content.attachments.any?
      content_text = content.text
    when Hash, Array
      content_raw = content
      content_text = nil
    end

    [content_text, attachments, content_raw]
  end
end
