class CreateLearnSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :learn_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :deck, null: false, foreign_key: true
      t.integer :cards_total,    default: 0, null: false
      t.integer :cards_mastered, default: 0, null: false
      t.datetime :started_at,    null: false
      t.datetime :finished_at

      t.timestamps
    end

    add_index :learn_sessions, [ :user_id, :deck_id ]
    add_index :learn_sessions, [ :user_id, :started_at ]
  end
end
