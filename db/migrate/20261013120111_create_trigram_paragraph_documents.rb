class CreateTrigramParagraphDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :trigram_paragraph_documents do |t|
      t.string :paragraph_id, null: false
      t.string :author
      t.string :work_title
      t.bigint :work_id
    end
    add_index :trigram_paragraph_documents, :paragraph_id, unique: true

    # The one line that differs from the generated migration: a trigram tokenizer in place of
    # unicode61, so that a Japanese query matches inside a sentence.
    create_virtual_table :trigram_paragraph_documents_fts, :fts5, [ "body", "tokenize='trigram'" ]
  end
end
