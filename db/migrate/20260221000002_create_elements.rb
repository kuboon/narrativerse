class CreateElements < ActiveRecord::Migration[8.0]
  def change
    create_table :elements do |t|
      t.references :user, null: false, foreign_key: true
      t.string :element_type, null: false
      t.string :name, null: false
      t.timestamps
    end

    add_index :elements, :element_type
  end
end
