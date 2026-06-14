class CreateLibraryItemsAndTransitionForkSystem < ActiveRecord::Migration[8.1]
  def up
    create_table :library_items do |t|
      t.integer :user_id, null: false
      t.integer :deck_id, null: false
      t.timestamps
    end
    add_index :library_items, :user_id
    add_index :library_items, :deck_id
    add_index :library_items, %i[user_id deck_id], unique: true
    add_foreign_key :library_items, :users, on_delete: :cascade
    add_foreign_key :library_items, :decks, on_delete: :cascade

    add_column :decks, :source_deck_id, :integer
    add_index  :decks, :source_deck_id
    add_foreign_key :decks, :decks, column: :source_deck_id, on_delete: :nullify

    # Backfill source_deck_id for owner-initiated duplicates
    execute <<~SQL
      UPDATE decks
      SET source_deck_id = forked_from_id
      WHERE forked_from_id IS NOT NULL
        AND user_id = (SELECT user_id FROM decks AS d2 WHERE d2.id = decks.forked_from_id)
    SQL

    # Backfill library_items for non-owner saves (one per unique user+original pair).
    #
    # KNOWN MIGRATION ARTIFACT — orphaned copy decks:
    # The old system created a physical Deck copy when a non-owner "saved" a deck.
    # This backfill creates a library_items row pointing to the original, but the
    # copied Deck record is intentionally left in place: some users may have edited
    # their copy and expect to keep it. As a result, affected users will see:
    #   (a) the original deck in their library (via library_items), AND
    #   (b) their old copied deck still present in their owned decks list.
    # This is a known, accepted artifact of migrating from fork-as-save to
    # library_items. A future cleanup task can offer users a way to delete
    # unmodified copies (source_deck_id present, no content changes).
    #
    # ON CONFLICT DO NOTHING handles the case where a user forked the same deck
    # multiple times (the original bug): only the first row survives. Syntax
    # works on both PostgreSQL 9.5+ and SQLite 3.24+ (Rails 8 requires 3.37+).
    execute <<~SQL
      INSERT INTO library_items (user_id, deck_id, created_at, updated_at)
      SELECT d.user_id,
             d.forked_from_id,
             COALESCE(d.forked_at, d.created_at),
             CURRENT_TIMESTAMP
      FROM decks d
      WHERE d.forked_from_id IS NOT NULL
        AND d.user_id != (SELECT d2.user_id FROM decks AS d2 WHERE d2.id = d.forked_from_id)
      ON CONFLICT DO NOTHING
    SQL

    remove_foreign_key :decks, column: :forked_from_id
    remove_column :decks, :forked_from_id
    remove_column :decks, :forks_count
    remove_column :decks, :forked_from_title_snapshot
    remove_column :decks, :forked_from_owner_display_snapshot
    remove_column :decks, :forked_at
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
