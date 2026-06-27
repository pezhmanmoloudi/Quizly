class AddGoogleOauthToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :google_uid, :string, if_not_exists: true
    add_column :users, :google_access_token, :string, if_not_exists: true
    add_index  :users, :google_uid, unique: true, if_not_exists: true
    change_column_null :users, :password_digest, true
  end
end
