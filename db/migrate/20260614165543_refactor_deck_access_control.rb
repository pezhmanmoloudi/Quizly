class RefactorDeckAccessControl < ActiveRecord::Migration[8.1]
  def up
    add_column :decks, :password_digest, :string

    execute "UPDATE decks SET password_digest = access_password_digest WHERE access_password_digest IS NOT NULL"
    execute "UPDATE decks SET visibility = 'public' WHERE visibility IN ('everyone', 'password_protected')"
    execute "UPDATE decks SET edit_permission = 'only_me' WHERE edit_permission = 'owner_only'"
    execute "UPDATE decks SET edit_permission = 'people_with_password' WHERE edit_permission = 'password_users'"

    change_column_default :decks, :visibility,      from: "everyone", to: "public"
    change_column_default :decks, :edit_permission, from: "owner_only", to: "only_me"

    remove_column :decks, :access_password_digest
    remove_index  :decks, name: "index_decks_on_share_token", if_exists: true
    remove_column :decks, :share_token
  end

  def down
    add_column :decks, :share_token, :string
    add_index  :decks, :share_token, unique: true
    add_column :decks, :access_password_digest, :string

    execute "UPDATE decks SET access_password_digest = password_digest WHERE password_digest IS NOT NULL"
    execute "UPDATE decks SET visibility = 'everyone' WHERE visibility = 'public'"
    execute "UPDATE decks SET edit_permission = 'owner_only' WHERE edit_permission = 'only_me'"
    execute "UPDATE decks SET edit_permission = 'password_users' WHERE edit_permission = 'people_with_password'"

    change_column_default :decks, :visibility,      from: "public",  to: "everyone"
    change_column_default :decks, :edit_permission, from: "only_me", to: "owner_only"

    remove_column :decks, :password_digest
  end
end
