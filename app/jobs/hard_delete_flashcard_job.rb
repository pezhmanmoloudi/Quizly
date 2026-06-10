class HardDeleteFlashcardJob < ApplicationJob
  queue_as :default

  def perform(flashcard_id)
    flashcard = Flashcard.unscoped.find_by(id: flashcard_id)
    return if flashcard.nil? || flashcard.deleted_at.nil?

    flashcard.destroy
  end
end
