class CreateEntities < ActiveRecord::Migration[8.0]
  def change
    create_table :entities do |t|
      t.string :entity_type, null: false
      t.string :name, null: false

      t.timestamps
    end

    add_index :entities, [:entity_type, :name], unique: true
    add_index :entities, :entity_type

    create_table :article_analysis_entities do |t|
      t.references :article_analysis, null: false, foreign_key: true
      t.references :entity, null: false, foreign_key: true

      t.timestamps
    end

    add_index :article_analysis_entities, [:article_analysis_id, :entity_id], unique: true, name: "idx_analysis_entities_unique"
  end
end
