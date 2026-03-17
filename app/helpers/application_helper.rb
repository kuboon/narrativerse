module ApplicationHelper
  PLOT_RICH_TEXT_TAGS = %w[p strong h1 h2 ruby rt].freeze

  def signed_mcp_url(user: current_user)
    token = signed_mcp_token(user)
    mcp_url(signature: token)
  end

  def signed_mcp_path(user: current_user)
    token = signed_mcp_token(user)
    mcp_path(signature: token)
  end

  def format_scene_text(text)
    simple_format(text)
  end

  def render_plot_title(title)
    rendered = render_plot_rich_text(title)
    return "（無題）" if rendered.blank?

    unwrap_single_paragraph(rendered)
  end

  def render_plot_summary(summary)
    rendered = render_plot_rich_text(summary)
    return "まだ概要がありません。" if rendered.blank?

    rendered
  end

  def render_plot_rich_text(value)
    sanitize(value.to_s, tags: PLOT_RICH_TEXT_TAGS).to_s.strip.html_safe
  end

  def message_choice_payload(message)
    return if message.content.present?

    payload = normalize_message_choice_payload(message.content_raw)
    return unless payload.is_a?(Hash)

    prompt = payload["question"].presence || payload["prompt"].presence
    choices = Array(payload["choices"]).filter_map { |choice| choice.to_s.strip.presence }
    return if prompt.blank? || choices.empty?

    {
      "prompt" => prompt,
      "choices" => choices
    }
  end

  private

  def signed_mcp_token(user)
    raise ArgumentError, "user is required" if user.blank?

    McpAuth.sign_user_id(user.id)
  end

  def unwrap_single_paragraph(html)
    match = html.match(%r{\A<p>(.*)</p>\z}m)
    return html unless match

    match[1].html_safe
  end

  def normalize_message_choice_payload(raw)
    case raw
    when Hash
      raw.stringify_keys
    when String
      parse_message_choice_payload(raw)
    when Array
      normalize_message_choice_payload(extract_message_choice_array_value(raw))
    end
  end

  def extract_message_choice_array_value(raw)
    return raw.last if raw.length == 2 && raw.first == "content_raw"
    return raw.first if raw.one?

    nil
  end

  def parse_message_choice_payload(raw)
    JSON.parse(raw).stringify_keys
  rescue JSON::ParserError, TypeError
    nil
  end
end
