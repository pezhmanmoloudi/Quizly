class RemoveRedundantUserIdIndexFromUserBadges < ActiveRecord::Migration[8.1]
  def change
    remove_index :user_badges, :user_id
  end
end
