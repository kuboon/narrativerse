class CreateElementRevisions < ActiveRecord::Migration[8.0]
  def change
    create_table :element_revisions do |t|
      t.references :element, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :revision, null: false
      t.text :summary
      t.text :text
      t.timestamps
    end

    add_index :element_revisions, [:element_id, :revision], unique: true
  end
end
