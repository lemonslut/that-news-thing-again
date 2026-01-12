class AddGithubOauthToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :github_uid, :string
    add_column :users, :github_username, :string
    add_column :users, :avatar_url, :string
    add_column :users, :provider, :string, default: "email"
    add_column :users, :allowed, :boolean, default: false, null: false

    add_index :users, :github_uid, unique: true

    # Make password_digest nullable for OAuth users
    change_column_null :users, :password_digest, true

    # Allow existing users by default
    reversible do |dir|
      dir.up do
        execute "UPDATE users SET allowed = true"
      end
    end
  end
end
