class CreateArticleCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :article_categories do |t|
      t.references :article, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.integer :weight
      t.timestamps
    end

    add_index :article_categories, [:article_id, :category_id], unique: true
    add_index :article_categories, :weight
  end
end
