class AddUniqueIndexToPlotElements < ActiveRecord::Migration[8.0]
  def change
    add_index :plot_elements, [ :plot_id, :element_id ], unique: true
  end
end
