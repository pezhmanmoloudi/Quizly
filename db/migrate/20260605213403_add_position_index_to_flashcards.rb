class AddPositionIndexToFlashcards < ActiveRecord::Migration[8.1]
  def change
    add_index :flashcards, :position
  end
end
