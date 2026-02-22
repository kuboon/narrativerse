class Plot < ApplicationRecord
  belongs_to :user
  belongs_to :scene
  has_many :plot_elements, dependent: :destroy
  has_many :plot_scene_links, dependent: :destroy
  has_many :plot_parent_links, foreign_key: :child_plot_id, dependent: :destroy
  has_many :parent_plots, through: :plot_parent_links, source: :parent_plot
  has_many :plot_child_links, class_name: "PlotParentLink", foreign_key: :parent_plot_id, dependent: :destroy
  has_many :child_plots, through: :plot_child_links, source: :child_plot

  validates :title, presence: true
  validates :summary, length: { maximum: 200 }, allow_nil: true
end
