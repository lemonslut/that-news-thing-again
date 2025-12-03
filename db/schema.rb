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

ActiveRecord::Schema[8.0].define(version: 2025_12_03_080814) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "article_calm_summaries", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.bigint "prompt_id"
    t.string "model_used", null: false
    t.text "summary", null: false
    t.jsonb "raw_response", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id"], name: "index_article_calm_summaries_on_article_id"
    t.index ["prompt_id"], name: "index_article_calm_summaries_on_prompt_id"
  end

  create_table "article_entities", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.bigint "entity_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id", "entity_id"], name: "index_article_entities_on_article_id_and_entity_id", unique: true
    t.index ["article_id"], name: "index_article_entities_on_article_id"
    t.index ["entity_id"], name: "index_article_entities_on_entity_id"
  end

  create_table "article_entity_extraction_entities", force: :cascade do |t|
    t.bigint "article_entity_extraction_id", null: false
    t.bigint "entity_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_entity_extraction_id", "entity_id"], name: "idx_extraction_entities_unique", unique: true
    t.index ["article_entity_extraction_id"], name: "idx_extraction_entities_extraction"
    t.index ["entity_id"], name: "index_article_entity_extraction_entities_on_entity_id"
  end

  create_table "article_entity_extractions", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.bigint "prompt_id"
    t.string "model_used", null: false
    t.jsonb "raw_response", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id"], name: "index_article_entity_extractions_on_article_id"
    t.index ["prompt_id"], name: "index_article_entity_extractions_on_prompt_id"
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

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "api_token"
    t.index ["api_token"], name: "index_users_on_api_token", unique: true
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "article_calm_summaries", "articles"
  add_foreign_key "article_calm_summaries", "prompts"
  add_foreign_key "article_entities", "articles"
  add_foreign_key "article_entities", "entities"
  add_foreign_key "article_entity_extraction_entities", "article_entity_extractions"
  add_foreign_key "article_entity_extraction_entities", "entities"
  add_foreign_key "article_entity_extractions", "articles"
  add_foreign_key "article_entity_extractions", "prompts"
  add_foreign_key "sessions", "users"
end
