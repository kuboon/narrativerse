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
end
