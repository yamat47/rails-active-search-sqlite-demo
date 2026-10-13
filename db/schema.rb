# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_13_120112) do
  create_table "paragraph_documents", force: :cascade do |t|
    t.string "paragraph_id", null: false
    t.string "author"
    t.string "work_title"
    t.bigint "work_id"
    t.index ["paragraph_id"], name: "index_paragraph_documents_on_paragraph_id", unique: true
  end

  create_table "paragraphs", force: :cascade do |t|
    t.integer "work_id", null: false
    t.integer "position", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["work_id", "position"], name: "index_paragraphs_on_work_id_and_position", unique: true
    t.index ["work_id"], name: "index_paragraphs_on_work_id"
  end

  create_table "segmented_paragraph_documents", force: :cascade do |t|
    t.string "paragraph_id", null: false
    t.string "author"
    t.string "work_title"
    t.bigint "work_id"
    t.index ["paragraph_id"], name: "index_segmented_paragraph_documents_on_paragraph_id", unique: true
  end

  create_table "trigram_paragraph_documents", force: :cascade do |t|
    t.string "paragraph_id", null: false
    t.string "author"
    t.string "work_title"
    t.bigint "work_id"
    t.index ["paragraph_id"], name: "index_trigram_paragraph_documents_on_paragraph_id", unique: true
  end

  create_table "works", force: :cascade do |t|
    t.string "title", null: false
    t.string "author", null: false
    t.integer "card_id", null: false
    t.string "card_url", null: false
    t.text "colophon"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["card_id"], name: "index_works_on_card_id", unique: true
  end

  add_foreign_key "paragraphs", "works"

  # Virtual tables defined in this database.
  # Note that virtual tables may not work with other database engines. Be careful if changing database.
  create_virtual_table "paragraph_documents_fts", "fts5", ["body"]
  create_virtual_table "segmented_paragraph_documents_fts", "fts5", ["body"]
  create_virtual_table "trigram_paragraph_documents_fts", "fts5", ["body", "tokenize='trigram'"]
end
