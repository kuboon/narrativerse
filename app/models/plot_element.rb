class PlotElement < ApplicationRecord
  belongs_to :plot
  belongs_to :element
  belongs_to :element_revision

  validates :summary, length: { maximum: 100 }, allow_nil: true
  validates :secrets, length: { maximum: 200 }, allow_nil: true
end
