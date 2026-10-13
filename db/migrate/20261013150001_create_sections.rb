class CreateSections < ActiveRecord::Migration[8.1]
  def change
    create_table :sections do |t|
      t.references :guide, null: false, foreign_key: true
      t.integer :position, null: false
      t.string :anchor, null: false
      t.string :title, null: false
      t.string :parent_title
      t.text :body, null: false

      t.timestamps
    end
    add_index :sections, [ :guide_id, :position ], unique: true
  end
end
