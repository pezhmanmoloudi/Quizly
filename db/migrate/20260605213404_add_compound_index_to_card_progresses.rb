class AddCompoundIndexToCardProgresses < ActiveRecord::Migration[8.1]
  def change
    add_index :card_progresses, [:user_id, :next_review_at]
  end
end
