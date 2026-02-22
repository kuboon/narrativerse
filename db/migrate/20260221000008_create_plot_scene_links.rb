class CreatePlotSceneLinks < ActiveRecord::Migration[8.0]
  def change
    create_table :plot_scene_links do |t|
      t.references :plot, null: false, foreign_key: true
      t.references :scene, null: false, foreign_key: true
      t.references :next_scene, foreign_key: { to_table: :scenes }
      t.timestamps
    end

    add_index :plot_scene_links, [:plot_id, :scene_id], unique: true
  end
end
