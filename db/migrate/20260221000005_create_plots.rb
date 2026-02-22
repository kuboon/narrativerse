class CreatePlots < ActiveRecord::Migration[8.0]
  def change
    create_table :plots do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :summary
      t.references :scene, null: false, foreign_key: true
      t.timestamps
    end
  end
end
