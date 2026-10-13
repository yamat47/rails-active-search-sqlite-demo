class CreateGuides < ActiveRecord::Migration[8.1]
  def change
    create_table :guides do |t|
      t.string :slug, null: false
      t.string :title, null: false
      t.text :description
      t.string :url, null: false
      t.string :source, null: false

      t.timestamps
    end
    add_index :guides, :slug, unique: true
  end
end
