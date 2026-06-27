class AddGithubOauthToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :github_uid, :string, if_not_exists: true
    add_column :users, :github_access_token, :string, if_not_exists: true
    add_index  :users, :github_uid, unique: true, if_not_exists: true
  end
end
