class CreateArticleAnalyses < ActiveRecord::Migration[8.0]
  def change
    create_table :article_analyses do |t|
      t.references :article, null: false, foreign_key: true, index: { unique: true }
      t.string :category, null: false
      t.jsonb :tags, null: false, default: []
      t.jsonb :entities, null: false, default: {}
      t.string :political_lean
      t.text :calm_summary, null: false
      t.string :model_used, null: false
      t.jsonb :raw_response, null: false, default: {}

      t.timestamps
    end

    add_index :article_analyses, :category
    add_index :article_analyses, :political_lean
    add_index :article_analyses, :tags, using: :gin
  end
end
