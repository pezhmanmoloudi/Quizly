class FixNotificationActorFk < ActiveRecord::Migration[8.1]
  def change
    # Drop the existing RESTRICT FK (PostgreSQL default) and replace with NULLIFY.
    # Without this, deleting a user who has acted on any notification raises a
    # PG::ForeignKeyViolation. SQLite silently skips FK enforcement unless
    # PRAGMA foreign_keys = ON, masking the bug in development.
    remove_foreign_key :notifications, column: :actor_id
    add_foreign_key :notifications, :users, column: :actor_id, on_delete: :nullify

    # Index required for efficient FK-cascade lookups and actor-scoped queries.
    add_index :notifications, :actor_id
  end
end
