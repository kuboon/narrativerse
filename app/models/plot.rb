class Plot < ApplicationRecord
  ALLOWED_RICH_TEXT_TAGS = %w[p strong h1 h2 ruby rt].freeze

  belongs_to :user
  belongs_to :scene, optional: true
  has_many :plot_elements, dependent: :destroy
  has_many :plot_scene_links, dependent: :destroy
  has_many :parent_plots, class_name: "Plot", foreign_key: "parent_plot_ids", primary_key: "id"

  attribute :parent_plot_ids, :json, default: []

  validates :summary, length: { maximum: 200 }

  # broadcasts
  broadcasts_refreshes

  # def parent_plots
  #   return [] if parent_plot_ids.empty?
  #   @parent_plots ||= Plot.where(id: parent_plot_ids)
  # end

  def story = @story ||= PlotStory.new(self)
end
