class RefactorAnalysisToSeparateConcerns < ActiveRecord::Migration[8.0]
  def change
    # Drop the old monolithic analysis tables
    drop_table :article_analysis_entities, if_exists: true
    drop_table :article_analyses, if_exists: true

    # Article entity extractions - audit trail for when/how we extracted entities
    create_table :article_entity_extractions do |t|
      t.references :article, null: false, foreign_key: true
      t.references :prompt, foreign_key: true
      t.string :model_used, null: false
      t.jsonb :raw_response, default: {}

      t.timestamps
    end

    # Article calm summaries - separate concern with its own prompt/model
    create_table :article_calm_summaries do |t|
      t.references :article, null: false, foreign_key: true
      t.references :prompt, foreign_key: true
      t.string :model_used, null: false
      t.text :summary, null: false
      t.jsonb :raw_response, default: {}

      t.timestamps
    end

    # Direct article <-> entity relationship (the canonical link)
    create_table :article_entities do |t|
      t.references :article, null: false, foreign_key: true
      t.references :entity, null: false, foreign_key: true

      t.timestamps
    end

    add_index :article_entities, [ :article_id, :entity_id ], unique: true

    # Join table for extraction provenance (which extraction found which entity)
    create_table :article_entity_extraction_entities do |t|
      t.references :article_entity_extraction, null: false, foreign_key: true, index: { name: "idx_extraction_entities_extraction" }
      t.references :entity, null: false, foreign_key: true

      t.timestamps
    end

    add_index :article_entity_extraction_entities,
              [ :article_entity_extraction_id, :entity_id ],
              unique: true,
              name: "idx_extraction_entities_unique"
  end
end
