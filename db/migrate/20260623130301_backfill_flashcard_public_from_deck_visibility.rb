class BackfillFlashcardPublicFromDeckVisibility < ActiveRecord::Migration[8.1]
  def up
    # Mark flashcards public when their deck is publicly visible
    Flashcard.joins(:deck)
             .where(decks: { visibility: "public" })
             .update_all(public: true)
  end

  def down
    Flashcard.update_all(public: false)
  end
end
