class AddUriToArticles < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    add_column :articles, :uri, :string

    Article.reset_column_information
    Article.find_each do |article|
      uri = article.raw_payload&.dig("uri")
      article.update_column(:uri, uri) if uri.present?
    end

    add_index :articles, :uri, unique: true, algorithm: :concurrently
  end

  def down
    remove_index :articles, :uri
    remove_column :articles, :uri
  end
end
