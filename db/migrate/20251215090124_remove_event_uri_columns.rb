class RemoveEventUriColumns < ActiveRecord::Migration[8.0]
  def change
    # Clear all stories and story associations first (they're based on bad event_uri groupings)
    reversible do |dir|
      dir.up do
        execute "UPDATE articles SET story_id = NULL"
        execute "DELETE FROM stories"
      end
    end

    remove_column :articles, :event_uri, :string
    remove_column :stories, :event_uri, :string
    remove_index :stories, :event_uri, if_exists: true
  end
end
