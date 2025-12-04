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

ActiveRecord::Schema[8.0].define(version: 2025_12_04_082435) do
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

  create_table "article_categories", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.bigint "category_id", null: false
    t.integer "weight"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id", "category_id"], name: "index_article_categories_on_article_id_and_category_id", unique: true
    t.index ["article_id"], name: "index_article_categories_on_article_id"
    t.index ["category_id"], name: "index_article_categories_on_category_id"
    t.index ["weight"], name: "index_article_categories_on_weight"
  end

  create_table "article_concepts", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.bigint "concept_id", null: false
    t.integer "score"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id", "concept_id"], name: "index_article_concepts_on_article_id_and_concept_id", unique: true
    t.index ["article_id"], name: "index_article_concepts_on_article_id"
    t.index ["concept_id"], name: "index_article_concepts_on_concept_id"
    t.index ["score"], name: "index_article_concepts_on_score"
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
    t.decimal "sentiment", precision: 10, scale: 6
    t.string "language"
    t.string "event_uri"
    t.boolean "is_duplicate", default: false
    t.index ["event_uri"], name: "index_articles_on_event_uri"
    t.index ["language"], name: "index_articles_on_language"
    t.index ["published_at"], name: "index_articles_on_published_at"
    t.index ["raw_payload"], name: "index_articles_on_raw_payload", using: :gin
    t.index ["sentiment"], name: "index_articles_on_sentiment"
    t.index ["source_name"], name: "index_articles_on_source_name"
    t.index ["url"], name: "index_articles_on_url", unique: true
  end

  create_table "categories", force: :cascade do |t|
    t.string "uri", null: false
    t.string "label", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["label"], name: "index_categories_on_label"
    t.index ["uri"], name: "index_categories_on_uri", unique: true
  end

  create_table "concepts", force: :cascade do |t|
    t.string "uri", null: false
    t.string "concept_type", null: false
    t.string "label", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["concept_type"], name: "index_concepts_on_concept_type"
    t.index ["label"], name: "index_concepts_on_label"
    t.index ["uri"], name: "index_concepts_on_uri", unique: true
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
  add_foreign_key "article_categories", "articles"
  add_foreign_key "article_categories", "categories"
  add_foreign_key "article_concepts", "articles"
  add_foreign_key "article_concepts", "concepts"
  add_foreign_key "sessions", "users"
end
