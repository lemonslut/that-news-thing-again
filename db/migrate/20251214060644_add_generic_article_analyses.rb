class AddGenericArticleAnalyses < ActiveRecord::Migration[8.0]
  def change
    create_table :article_analyses do |t|
      t.references :article, null: false, foreign_key: true
      t.references :prompt, foreign_key: true
      t.string :analysis_type, null: false
      t.string :model_used, null: false
      t.jsonb :result, null: false, default: {}
      t.jsonb :raw_response, default: {}

      t.timestamps
    end

    add_index :article_analyses, [ :article_id, :analysis_type ]
    add_index :article_analyses, :analysis_type
    add_index :article_analyses, :created_at

    # Migrate existing calm summaries
    reversible do |dir|
      dir.up do
        execute <<~SQL
          INSERT INTO article_analyses (article_id, prompt_id, analysis_type, model_used, result, raw_response, created_at, updated_at)
          SELECT
            article_id,
            prompt_id,
            'calm_summary',
            model_used,
            jsonb_build_object('calm_summary', summary),
            raw_response,
            created_at,
            updated_at
          FROM article_calm_summaries
        SQL
      end
    end
  end
end
