class CreateCardProgresses < ActiveRecord::Migration[8.0]
  def change
    create_table :card_progresses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :flashcard, null: false, foreign_key: true
      t.float   :ease_factor,  null: false, default: 2.5
      t.integer :interval,     null: false, default: 1
      t.integer :repetitions,  null: false, default: 0
      t.datetime :next_review_at
      t.datetime :last_reviewed_at

      t.timestamps
    end

    add_index :card_progresses, [:user_id, :flashcard_id], unique: true
    add_index :card_progresses, :next_review_at
  end
end
