class AddLanguagesToFlashcards < ActiveRecord::Migration[8.1]
  def change
    add_column :flashcards, :front_language, :string unless column_exists?(:flashcards, :front_language)
    add_column :flashcards, :back_language,  :string unless column_exists?(:flashcards, :back_language)
  end
end
