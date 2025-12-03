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

ActiveRecord::Schema[8.0].define(version: 2025_12_03_070052) do
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
    t.bigint "prompt_id"
    t.index ["article_id"], name: "index_article_analyses_on_article_id", unique: true
    t.index ["category"], name: "index_article_analyses_on_category"
    t.index ["political_lean"], name: "index_article_analyses_on_political_lean"
    t.index ["prompt_id"], name: "index_article_analyses_on_prompt_id"
    t.index ["tags"], name: "index_article_analyses_on_tags", using: :gin
  end

  create_table "article_analysis_entities", force: :cascade do |t|
    t.bigint "article_analysis_id", null: false
    t.bigint "entity_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_analysis_id", "entity_id"], name: "idx_analysis_entities_unique", unique: true
    t.index ["article_analysis_id"], name: "index_article_analysis_entities_on_article_analysis_id"
    t.index ["entity_id"], name: "index_article_analysis_entities_on_entity_id"
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

  create_table "entities", force: :cascade do |t|
    t.string "entity_type", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["entity_type", "name"], name: "index_entities_on_entity_type_and_name", unique: true
    t.index ["entity_type"], name: "index_entities_on_entity_type"
  end

  create_table "prompts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body", null: false
    t.integer "version", default: 1, null: false
    t.boolean "active", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_prompts_on_active"
    t.index ["name", "version"], name: "index_prompts_on_name_and_version", unique: true
  end

  add_foreign_key "article_analyses", "articles"
  add_foreign_key "article_analyses", "prompts"
  add_foreign_key "article_analysis_entities", "article_analyses"
  add_foreign_key "article_analysis_entities", "entities"
end
