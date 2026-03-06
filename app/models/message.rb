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
    tool_result? && parent_tool_call&.name == CHOICE_TOOL_NAME
  end

  def choice_payload
    return unless choice_message?
    return if content.blank?

    payload = JSON.parse(content)
    return unless payload.is_a?(Hash)
    return unless payload["type"] == "choices"

    choices = Array(payload["choices"])
              .map { |choice| choice.to_s.strip }
              .reject(&:blank?)
              .uniq

    return if choices.empty?

    {
      "prompt" => payload["prompt"].presence || "次の操作を選んでください。",
      "choices" => choices
    }
  rescue JSON::ParserError
    nil
  end

  def thinking_message?
    return false if choice_message?

    role.to_s == "system" || tool_call? || tool_result?
  end
end
