class CreatePlotElements < ActiveRecord::Migration[8.0]
  def change
    create_table :plot_elements do |t|
      t.references :plot, null: false, foreign_key: true
      t.references :element, null: false, foreign_key: true
      t.references :element_revision, null: false, foreign_key: true
      t.text :summary
      t.text :secrets
      t.timestamps
    end
  end
end
