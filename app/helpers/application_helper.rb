module ApplicationHelper
  PLOT_RICH_TEXT_TAGS = %w[p strong h1 h2 ruby rt].freeze

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

  def tool_name_label(tool_name)
    mapping = {
      "plot_chatbot--add_plot_element" => "要素の追加",
      "plot_chatbot--update_plot_element" => "要素の更新",
      "plot_chatbot--add_scene" => "シーンの追加",
      "plot_chatbot--update_scene" => "シーンの更新",
      "plot_chatbot--search_elements" => "プロット外の要素を検索",
      "plot_chatbot--list_plot_elements" => "プロット内の全要素を確認",
      "plot_chatbot--list_scenes" => "全てのシーンを確認",
      "plot_chatbot--present_choices" => "選択肢を提示"
    }
    mapping[tool_name.to_s] || tool_name.to_s.split("--").last&.titleize || tool_name
  end

  private

  def unwrap_single_paragraph(html)
    match = html.match(%r{\A<p>(.*)</p>\z}m)
    return html unless match

    match[1].html_safe
  end
end
