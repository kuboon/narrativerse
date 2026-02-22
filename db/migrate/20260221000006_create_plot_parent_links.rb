class CreatePlotParentLinks < ActiveRecord::Migration[8.0]
  def change
    create_table :plot_parent_links do |t|
      t.references :child_plot, null: false, foreign_key: { to_table: :plots }
      t.references :parent_plot, null: false, foreign_key: { to_table: :plots }
      t.timestamps
    end

    add_index :plot_parent_links, [ :child_plot_id, :parent_plot_id ], unique: true, name: "index_plot_parents_on_child_and_parent"
  end
end
