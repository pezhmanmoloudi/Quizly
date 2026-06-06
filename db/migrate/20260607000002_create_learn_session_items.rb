class CreateLearnSessionItems < ActiveRecord::Migration[8.1]
  def change
    create_table :learn_session_items do |t|
      t.references :learn_session, null: false, foreign_key: true
      t.references :flashcard,     null: false, foreign_key: true
      t.string  :status,         default: "unseen", null: false
      t.integer :attempts,       default: 0,        null: false
      t.integer :correct_streak, default: 0,        null: false
      t.integer :position,       null: false

      t.timestamps
    end

    add_index :learn_session_items, [ :learn_session_id, :flashcard_id ], unique: true
    add_index :learn_session_items, [ :learn_session_id, :status ]
    add_index :learn_session_items, [ :learn_session_id, :position ]
  end
end
