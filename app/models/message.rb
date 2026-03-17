class Message < ApplicationRecord
  acts_as_message
  has_many_attached :attachments
  broadcasts_to :chat

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
end
