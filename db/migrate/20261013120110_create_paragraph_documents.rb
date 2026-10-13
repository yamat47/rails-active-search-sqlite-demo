class CreateParagraphDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :paragraph_documents do |t|
      t.string :paragraph_id, null: false
      t.string :author
      t.string :work_title
      t.bigint :work_id
    end
    add_index :paragraph_documents, :paragraph_id, unique: true

    create_virtual_table :paragraph_documents_fts, :fts5, [ "body" ]
  end
end
