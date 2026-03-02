class Plot < ApplicationRecord
  belongs_to :user
  belongs_to :scene
  has_many :plot_elements, dependent: :destroy
  has_many :plot_scene_links, dependent: :destroy

  attribute :parent_plot_ids, :json, default: []

  validates :title, presence: true
  validates :summary, length: { maximum: 200 }, allow_nil: true

  def parent_plots
    return [] if parent_plot_ids.empty?
    Plot.where(id: parent_plot_ids)
  end
end
