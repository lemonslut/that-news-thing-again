class CreateStories < ActiveRecord::Migration[8.0]
  def change
    create_table :stories do |t|
      t.string :title
      t.string :event_uri
      t.datetime :first_published_at
      t.datetime :last_published_at
      t.integer :articles_count, default: 0

      t.timestamps
    end

    add_index :stories, :event_uri, unique: true

    add_reference :articles, :story, foreign_key: true, index: true
  end
end
