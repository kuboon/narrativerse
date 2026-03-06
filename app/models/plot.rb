class Plot < ApplicationRecord
  ALLOWED_RICH_TEXT_TAGS = %w[p strong h1 h2 ruby rt].freeze

  belongs_to :user
  belongs_to :scene, optional: true
  has_many :plot_elements, dependent: :destroy
  has_many :plot_scene_links, dependent: :destroy

  attribute :parent_plot_ids, :json, default: []

  before_validation :normalize_rich_text_attributes

  validate :summary_plain_text_length_within_limit

  def parent_plots
    return [] if parent_plot_ids.empty?
    Plot.where(id: parent_plot_ids)
  end

  private

  def normalize_rich_text_attributes
    self.title = sanitize_rich_text(title, required: false)
    self.summary = sanitize_rich_text(summary, required: false)
  end

  def sanitize_rich_text(value, required:)
    sanitized = ActionController::Base.helpers.sanitize(value.to_s, tags: ALLOWED_RICH_TEXT_TAGS).strip
    plain_text = ActionController::Base.helpers.strip_tags(sanitized).squish

    return nil if plain_text.blank? && !required
    return nil if plain_text.blank? && required

    sanitized
  end

  def summary_plain_text_length_within_limit
    return if summary.blank?

    plain_text = ActionController::Base.helpers.strip_tags(summary).squish
    return if plain_text.length <= 200

    errors.add(:summary, :too_long, count: 200)
  end
end
