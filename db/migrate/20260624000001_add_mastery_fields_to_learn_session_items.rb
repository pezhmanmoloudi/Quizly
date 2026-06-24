class AddMasteryFieldsToLearnSessionItems < ActiveRecord::Migration[8.1]
  def change
    add_column :learn_session_items, :mastery_score,   :integer,  default: 0, null: false
    add_column :learn_session_items, :confusion_count, :integer,  default: 0, null: false
    add_column :learn_session_items, :last_seen_at,    :datetime
  end
end
