class CreateArticleConcepts < ActiveRecord::Migration[8.0]
  def change
    create_table :article_concepts do |t|
      t.references :article, null: false, foreign_key: true
      t.references :concept, null: false, foreign_key: true
      t.integer :score
      t.timestamps
    end

    add_index :article_concepts, [:article_id, :concept_id], unique: true
    add_index :article_concepts, :score
  end
end
