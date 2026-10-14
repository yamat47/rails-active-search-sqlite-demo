class CreatePorterSectionDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :porter_section_documents do |t|
      t.string :section_id, null: false
      t.string :guide_title
      t.bigint :guide_id
    end
    add_index :porter_section_documents, :section_id, unique: true

    # The one line that differs from the generated migration: the Porter stemmer, so that a query
    # matches the other forms of its words.
    create_virtual_table :porter_section_documents_fts, :fts5, [ "title", "body", "tokenize='porter'" ]
  end
end
