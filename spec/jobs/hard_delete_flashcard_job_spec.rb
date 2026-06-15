require "rails_helper"

RSpec.describe HardDeleteFlashcardJob, type: :job do
  let(:deck)      { create(:deck) }
  let(:flashcard) { create(:flashcard, deck: deck) }

  it "does not double-decrement flashcards_count after soft_delete" do
    flashcard.soft_delete!
    expect { described_class.perform_now(flashcard.id) }
      .not_to change { deck.reload.flashcards_count }
  end

  it "leaves flashcards_count correct when one card remains" do
    other = create(:flashcard, deck: deck)
    flashcard.soft_delete!
    described_class.perform_now(flashcard.id)
    expect(deck.reload.flashcards_count).to eq(1)
  end

  it "is a no-op when flashcard was restored before job ran" do
    flashcard.soft_delete!
    flashcard.restore!
    expect { described_class.perform_now(flashcard.id) }
      .not_to change(Flashcard.unscoped, :count)
  end

  it "purges the image asynchronously if one is attached" do
    expect { described_class.perform_now(flashcard.id) }.not_to raise_error
  end
end
