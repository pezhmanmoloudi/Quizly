class CreateTestSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :test_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :deck, null: false, foreign_key: true
      t.text    :questions_data,   null: false
      t.integer :questions_total,  default: 0, null: false
      t.integer :current_index,    default: 0, null: false
      t.integer :score,            default: 0, null: false
      t.datetime :started_at,      null: false
      t.datetime :finished_at

      t.timestamps
    end

    add_index :test_sessions, [ :user_id, :deck_id ]
    add_index :test_sessions, [ :user_id, :started_at ]
  end
end
