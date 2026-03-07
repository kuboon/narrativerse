class Message < ApplicationRecord
  acts_as_message tool_calls_foreign_key: :message_id
  has_many_attached :attachments
  broadcasts_to ->(message) { "chat_#{message.chat_id}" }

  CHOICE_TOOL_NAME = "present_choices"

  def broadcast_append_chunk(content)
    if choice_payload.present?
      broadcast_replace_to "chat_#{chat_id}",
        target: "message_#{id}",
        partial: "messages/message",
        locals: { message: self }
      return
    end

    broadcast_append_to "chat_#{chat_id}",
      target: "message_#{id}_content",
      partial: "messages/content",
      locals: { content: content }
  end

  def choice_message?
    choice_payload.present?
  end

  def choice_payload
    payload = extract_choice_payload
    return unless payload.is_a?(Hash)
    return unless payload["type"] == "choices"

    if tool_result?
      tool_name = parent_tool_call&.name.to_s
      if tool_name.present? && !choice_tool_call_name?(tool_name)
        return
      end
    end

    choices = Array(payload["choices"])
              .map { |choice| choice.to_s.strip }
              .reject(&:blank?)
              .uniq

    return if choices.empty?

    {
      "prompt" => payload["prompt"].presence || "次の操作を選んでください。",
      "choices" => choices
    }
  end

  def thinking_message?
    return false if choice_payload.present?

    role.to_s == "system" || tool_call? || tool_result? || thinking_text.present?
  end

  private

  def extract_choice_payload
    return if content.blank?

    candidates = [
      content,
      extract_markdown_json(content),
      extract_first_json_object(content)
    ].compact

    candidates.each do |candidate|
      parsed = parse_json(candidate)
      next unless parsed

      return parse_json(parsed) if parsed.is_a?(String)
      return parsed if parsed.is_a?(Hash)
    end

    extract_partial_choice_payload(content)
  end

  def extract_partial_choice_payload(text)
    return unless text.include?("\"type\"") && text.include?("choices")

    prompt = extract_partial_json_string(text, "prompt")
    choices = extract_partial_choices(text)
    return if choices.empty?

    {
      "type" => "choices",
      "prompt" => prompt.presence || "次の操作を選んでください。",
      "choices" => choices
    }
  end

  def extract_partial_choices(text)
    match = text.match(/"choices"\s*:\s*\[(.*)\z/m)
    return [] unless match

    match[1]
      .scan(/"((?:\\.|[^"\\])*)"/m)
      .flatten
      .map { |choice| unescape_json_string(choice).strip }
      .reject(&:blank?)
      .uniq
  end

  def extract_partial_json_string(text, key)
    match = text.match(/"#{Regexp.escape(key)}"\s*:\s*"((?:\\.|[^"\\])*)"/m)
    return unless match

    unescape_json_string(match[1])
  end

  def unescape_json_string(fragment)
    parse_json("\"#{fragment}\"") || fragment
  end

  def choice_tool_call_name?(name)
    normalized = name.to_s
    normalized == CHOICE_TOOL_NAME ||
      normalized.end_with?("--#{CHOICE_TOOL_NAME}") ||
      normalized == "plot_chatbot--present_choices"
  end

  def extract_markdown_json(text)
    match = text.match(/```(?:json)?\s*([\s\S]*?)```/i)
    match && match[1].to_s.strip
  end

  def extract_first_json_object(text)
    start_idx = text.index("{")
    end_idx = text.rindex("}")
    return if start_idx.nil? || end_idx.nil? || end_idx <= start_idx

    text[start_idx..end_idx]
  end

  def parse_json(raw)
    return if raw.blank?

    JSON.parse(raw)
  rescue JSON::ParserError
    nil
  end
end
