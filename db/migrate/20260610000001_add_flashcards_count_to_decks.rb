class AddFlashcardsCountToDecks < ActiveRecord::Migration[8.1]
  def up
    add_column :decks, :flashcards_count, :integer, default: 0, null: false unless column_exists?(:decks, :flashcards_count)
    execute <<~SQL
      UPDATE decks
      SET flashcards_count = (SELECT COUNT(*) FROM flashcards WHERE flashcards.deck_id = decks.id)
    SQL
  end

  def down
    remove_column :decks, :flashcards_count
  end
end
