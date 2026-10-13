class CreateWorks < ActiveRecord::Migration[8.1]
  def change
    create_table :works do |t|
      t.string :title, null: false
      t.string :author, null: false
      t.integer :card_id, null: false
      t.string :card_url, null: false
      t.text :colophon

      t.timestamps
    end
    add_index :works, :card_id, unique: true
  end
end
