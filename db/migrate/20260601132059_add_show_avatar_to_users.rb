class AddShowAvatarToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :show_avatar, :boolean, default: true, null: false
  end
end
