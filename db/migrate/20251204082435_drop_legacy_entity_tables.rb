class DropLegacyEntityTables < ActiveRecord::Migration[8.0]
  def up
    drop_table :article_entity_extraction_entities, if_exists: true
    drop_table :article_entity_extractions, if_exists: true
    drop_table :article_entities, if_exists: true
    drop_table :entities, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
