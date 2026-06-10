class AddDeletedAtToFlashcards < ActiveRecord::Migration[8.1]
  def change
    add_column :flashcards, :deleted_at, :datetime
    add_index :flashcards, :deleted_at
  end
end
