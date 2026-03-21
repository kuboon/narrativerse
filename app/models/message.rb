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

    content_text, attachments_to_persist, content_raw = prepare_content_for_storage(message.content)

    attrs = {
      role: message.role,
      content: content_text,
      input_tokens: message.input_tokens,
      output_tokens: message.output_tokens,
      cached_tokens: message.cached_tokens,
      cache_creation_tokens: message.cache_creation_tokens,
      thinking_text: message.thinking&.text,
      thinking_signature: message.thinking&.signature,
      thinking_tokens: message.thinking_tokens,
      content_raw:
    }

    if message.role.to_s == "assistant" && message.tool_call?
      attrs[:content_raw] ||= {}
      attrs[:content_raw]["tool_calls"] = message.tool_calls.transform_values(&:to_h)
    elsif message.role.to_s == "tool"
      attrs[:content_raw] ||= {}
      attrs[:content_raw]["tool_call_id"] = message.tool_call_id
    end

    assign_attributes(attrs)
  end

  def extract_tool_calls
    return {} unless role == "assistant" && content_raw.is_a?(Hash) && content_raw["tool_calls"]

    content_raw["tool_calls"].transform_values do |tc|
      RubyLLM::ToolCall.new(
        id: tc["id"],
        name: tc["name"],
        arguments: tc["arguments"],
        thought_signature: tc["thought_signature"]
      )
    end
  end

  def extract_tool_call_id
    return nil unless role == "tool" && content_raw.is_a?(Hash)
    content_raw["tool_call_id"]
  end

  def to_partial_path
    "messages/message"
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

    [ content_text, attachments, content_raw ]
  end
end
