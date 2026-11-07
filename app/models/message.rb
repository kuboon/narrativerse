class Message < ApplicationRecord
  acts_as_message
  has_many_attached :attachments

  def choice_payload
    payload = parsed_json if role == "assistant"
    return unless payload.is_a?(Hash)

    question = payload["question"].presence
    choices = Array(payload["choices"]).filter_map { |choice| choice.to_s.strip.presence }
    return if question.blank? || choices.empty?

    { "question" => question, "choices" => choices }
  end

  def tool_payload
    payload = parsed_json if role == "tool"
    payload if payload.is_a?(Hash)
  end

  def to_partial_path
    "messages/message"
  end

  private

  def parsed_json
    JSON.parse(content.to_s)
  rescue JSON::ParserError
    nil
  end
end
