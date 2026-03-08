class Message < ApplicationRecord
  acts_as_message tool_calls_foreign_key: :message_id
  has_many_attached :attachments
  broadcasts_to ->(message) { "chat_#{message.chat_id}" }

  CHOICE_TOOL_NAME = "present_choices"

  def broadcast_append_chunk(content)
    broadcast_append_to "chat_#{chat_id}",
      target: "message_#{id}_content",
      partial: "messages/content",
      locals: { content: content }
  end

  def choice_message?
    choice_payload.present?
  end

  def choice_payload
    return unless parseable_choices?

    parsed = parse_json(content)
    parsed = parse_json(parsed) if parsed.is_a?(String)
    parsed ||= extract_json_object(content)
    return unless parsed.is_a?(Hash) && parsed["type"] == "choices"

    choices = Array(parsed["choices"]).map { |c| c.to_s.strip }.reject(&:blank?).uniq
    return if choices.empty?

    { "prompt" => parsed["prompt"].presence || "次の操作を選んでください。", "choices" => choices }
  end

  def thinking_message?
    return false if choice_payload.present?

    role.to_s == "system" || tool_call? || tool_result? || thinking_text.present?
  end

  private

  def parseable_choices?
    return false if content.blank?
    return choice_tool_call_name?(parent_tool_call&.name) if tool_result?

    role.to_s == "assistant"
  end

  def choice_tool_call_name?(name)
    n = name.to_s
    n == CHOICE_TOOL_NAME || n.end_with?("--#{CHOICE_TOOL_NAME}")
  end

  def extract_json_object(text)
    start_idx = text.index("{")
    end_idx   = text.rindex("}")
    return if start_idx.nil? || end_idx.nil? || end_idx <= start_idx

    parse_json(text[start_idx..end_idx])
  end

  def parse_json(raw)
    return if raw.blank?

    JSON.parse(raw)
  rescue JSON::ParserError
    nil
  end
end
