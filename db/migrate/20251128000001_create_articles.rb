class CreateArticles < ActiveRecord::Migration[8.0]
  def change
    create_table :articles do |t|
      t.string :source_id
      t.string :source_name, null: false
      t.string :author
      t.string :title, null: false
      t.text :description
      t.string :url, null: false
      t.string :image_url
      t.datetime :published_at, null: false
      t.text :content
      t.jsonb :raw_payload, null: false, default: {}

      t.timestamps
    end

    add_index :articles, :url, unique: true
    add_index :articles, :published_at
    add_index :articles, :source_name
    add_index :articles, :raw_payload, using: :gin
  end
end
