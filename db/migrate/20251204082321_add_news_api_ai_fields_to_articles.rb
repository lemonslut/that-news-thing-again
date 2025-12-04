class AddNewsApiAiFieldsToArticles < ActiveRecord::Migration[8.0]
  def change
    add_column :articles, :sentiment, :decimal, precision: 10, scale: 6
    add_column :articles, :language, :string
    add_column :articles, :event_uri, :string
    add_column :articles, :is_duplicate, :boolean, default: false

    add_index :articles, :sentiment
    add_index :articles, :language
    add_index :articles, :event_uri
  end
end
