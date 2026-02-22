class CreateScenes < ActiveRecord::Migration[8.0]
  def change
    create_table :scenes do |t|
      t.references :user, null: false, foreign_key: true
      t.text :text, null: false
      t.timestamps
    end
  end
end
