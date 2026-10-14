class CreateSectionDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :section_documents do |t|
      t.string :section_id, null: false
      t.string :guide_title
      t.bigint :guide_id
    end
    add_index :section_documents, :section_id, unique: true

    create_virtual_table :section_documents_fts, :fts5, [ "title", "body" ]
  end
end
