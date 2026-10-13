class CreateTrigramSectionDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :trigram_section_documents do |t|
      t.string :section_id, null: false
      t.string :guide_title
      t.bigint :guide_id
    end
    add_index :trigram_section_documents, :section_id, unique: true

    # The one line that differs from the generated migration: a trigram tokenizer, so that a query
    # matches inside a word.
    create_virtual_table :trigram_section_documents_fts, :fts5, [ "title", "body", "tokenize='trigram'" ]
  end
end
