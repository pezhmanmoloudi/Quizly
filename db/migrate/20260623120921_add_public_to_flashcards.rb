class AddPublicToFlashcards < ActiveRecord::Migration[8.1]
  def change
    add_column :flashcards, :public, :boolean, default: false, null: false
    add_index  :flashcards, [:public, :front_language]
    add_index  :flashcards, [:public, :back_language]
  end
end
