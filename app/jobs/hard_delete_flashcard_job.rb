class HardDeleteFlashcardJob < ApplicationJob
  queue_as :default

  def perform(flashcard_id)
    flashcard = Flashcard.unscoped.find_by(id: flashcard_id)
    return if flashcard.nil? || flashcard.deleted_at.nil?

    # Use delete (not destroy) — soft_delete! already decremented flashcards_count.
    # destroy would fire the counter_cache after_destroy callback and double-decrement.
    flashcard.card_progresses.delete_all
    flashcard.learn_session_items.delete_all
    flashcard.image.purge_later if flashcard.image.attached?
    flashcard.delete
  end
end
