class AddForkSnapshotToDecks < ActiveRecord::Migration[8.1]
  def change
    add_column :decks, :forked_from_title_snapshot, :string
    add_column :decks, :forked_from_owner_display_snapshot, :string
    add_column :decks, :forked_at, :datetime
  end
end
