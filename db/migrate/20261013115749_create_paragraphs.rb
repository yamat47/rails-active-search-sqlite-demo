class CreateParagraphs < ActiveRecord::Migration[8.1]
  def change
    create_table :paragraphs do |t|
      t.references :work, null: false, foreign_key: true
      t.integer :position, null: false
      t.text :body, null: false

      t.timestamps
    end
    add_index :paragraphs, [ :work_id, :position ], unique: true
  end
end
