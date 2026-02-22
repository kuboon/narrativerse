class PlotParentLink < ApplicationRecord
  belongs_to :child_plot, class_name: "Plot"
  belongs_to :parent_plot, class_name: "Plot"
end
