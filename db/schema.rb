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

ActiveRecord::Schema[8.0].define(version: 2025_11_28_000002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "article_analyses", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.string "category", null: false
    t.jsonb "tags", default: [], null: false
    t.jsonb "entities", default: {}, null: false
    t.string "political_lean"
    t.text "calm_summary", null: false
    t.string "model_used", null: false
    t.jsonb "raw_response", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id"], name: "index_article_analyses_on_article_id", unique: true
    t.index ["category"], name: "index_article_analyses_on_category"
    t.index ["political_lean"], name: "index_article_analyses_on_political_lean"
    t.index ["tags"], name: "index_article_analyses_on_tags", using: :gin
  end

  create_table "articles", force: :cascade do |t|
    t.string "source_id"
    t.string "source_name", null: false
    t.string "author"
    t.string "title", null: false
    t.text "description"
    t.string "url", null: false
    t.string "image_url"
    t.datetime "published_at", null: false
    t.text "content"
    t.jsonb "raw_payload", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["published_at"], name: "index_articles_on_published_at"
    t.index ["raw_payload"], name: "index_articles_on_raw_payload", using: :gin
    t.index ["source_name"], name: "index_articles_on_source_name"
    t.index ["url"], name: "index_articles_on_url", unique: true
  end

  add_foreign_key "article_analyses", "articles"
end
