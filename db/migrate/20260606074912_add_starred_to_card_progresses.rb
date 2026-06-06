class AddStarredToCardProgresses < ActiveRecord::Migration[8.1]
  def change
    add_column :card_progresses, :starred, :boolean, null: false, default: false
    add_index  :card_progresses, [:user_id, :starred]
  end
end
