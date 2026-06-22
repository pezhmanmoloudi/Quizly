class CreateFollows < ActiveRecord::Migration[8.1]
  def change
    create_table :follows do |t|
      t.bigint :follower_id, null: false
      t.bigint :followed_id, null: false
      t.timestamps
    end

    # Compound unique index: prevents duplicate rows and is the DB-level race condition guard.
    # A concurrent duplicate INSERT fails at the DB, not silently in Ruby.
    add_index :follows, [ :follower_id, :followed_id ], unique: true,
              name: "index_follows_on_follower_id_and_followed_id"

    # Reverse index: powers "who follows this user" queries and cascade lookups.
    add_index :follows, :followed_id, name: "index_follows_on_followed_id"

    # Cascade deletes: removing either user removes all follow rows involving them.
    add_foreign_key :follows, :users, column: :follower_id, on_delete: :cascade
    add_foreign_key :follows, :users, column: :followed_id, on_delete: :cascade

    # DB-level self-follow constraint: belt to the model validation's suspenders.
    reversible do |dir|
      dir.up do
        execute <<~SQL
          ALTER TABLE follows
            ADD CONSTRAINT follows_no_self_follow
            CHECK (follower_id <> followed_id);
        SQL
      end
      dir.down { execute "ALTER TABLE follows DROP CONSTRAINT follows_no_self_follow;" }
    end
  end
end
