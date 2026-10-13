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

ActiveRecord::Schema[8.1].define(version: 2026_10_13_150004) do
  create_table "guides", force: :cascade do |t|
    t.string "slug", null: false
    t.string "title", null: false
    t.text "description"
    t.string "url", null: false
    t.string "source", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_guides_on_slug", unique: true
  end

  create_table "porter_section_documents", force: :cascade do |t|
    t.string "section_id", null: false
    t.string "guide_title"
    t.bigint "guide_id"
    t.index ["section_id"], name: "index_porter_section_documents_on_section_id", unique: true
  end

  create_table "section_documents", force: :cascade do |t|
    t.string "section_id", null: false
    t.string "guide_title"
    t.bigint "guide_id"
    t.index ["section_id"], name: "index_section_documents_on_section_id", unique: true
  end

  create_table "sections", force: :cascade do |t|
    t.integer "guide_id", null: false
    t.integer "position", null: false
    t.string "anchor", null: false
    t.string "title", null: false
    t.string "parent_title"
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["guide_id", "position"], name: "index_sections_on_guide_id_and_position", unique: true
    t.index ["guide_id"], name: "index_sections_on_guide_id"
  end

  create_table "trigram_section_documents", force: :cascade do |t|
    t.string "section_id", null: false
    t.string "guide_title"
    t.bigint "guide_id"
    t.index ["section_id"], name: "index_trigram_section_documents_on_section_id", unique: true
  end

  add_foreign_key "sections", "guides"

  # Virtual tables defined in this database.
  # Note that virtual tables may not work with other database engines. Be careful if changing database.
  create_virtual_table "porter_section_documents_fts", "fts5", ["title", "body", "tokenize='porter'"]
  create_virtual_table "section_documents_fts", "fts5", ["title", "body"]
  create_virtual_table "trigram_section_documents_fts", "fts5", ["title", "body", "tokenize='trigram'"]
end
