class CreateArticleSubjects < ActiveRecord::Migration[8.0]
  def change
    create_table :article_subjects do |t|
      t.references :article, null: false, foreign_key: true
      t.references :concept, null: false, foreign_key: true

      t.timestamps
    end

    add_index :article_subjects, [:article_id, :concept_id], unique: true
  end
end
