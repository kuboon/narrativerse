class PlotElement < ApplicationRecord
  belongs_to :plot
  belongs_to :element
  belongs_to :element_revision

  validates :element_id, uniqueness: { scope: :plot_id }
  validates :summary, length: { maximum: 100 }, allow_nil: true
  validates :secrets, length: { maximum: 200 }, allow_nil: true

  after_create_commit -> { broadcast_append_to plot, target: "plot-elements", partial: "plot_elements/plot_element", locals: { plot_element: self, highlight: true } }
  after_update_commit -> { broadcast_replace_to plot, target: self, partial: "plot_elements/plot_element", locals: { plot_element: self, highlight: true } }
  after_destroy_commit -> { broadcast_remove_to plot, target: self }
end
