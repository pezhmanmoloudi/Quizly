class CreateStudySessions < ActiveRecord::Migration[8.1]
  def change
    create_table :study_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :deck, null: false, foreign_key: true
      t.integer :cards_total,    null: false, default: 0
      t.integer :cards_reviewed, null: false, default: 0
      t.integer :cards_correct,  null: false, default: 0
      t.datetime :started_at,    null: false
      t.datetime :finished_at
      t.timestamps
    end

    add_index :study_sessions, [:user_id, :started_at]
    add_index :study_sessions, [:user_id, :deck_id]
  end
end
