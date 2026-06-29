module Decks
  class LearnSessionService
    def self.find_or_create(deck:, user:, session_id:, flashcard_ids: nil)
      new(deck:, user:, session_id:, flashcard_ids:).find_or_create
    end

    def initialize(deck:, user:, session_id:, flashcard_ids: nil)
      @deck          = deck
      @user          = user
      @session_id    = session_id
      @flashcard_ids = flashcard_ids
    end

    def find_or_create
      if @session_id
        existing = @user.learn_sessions.find_by(id: @session_id, finished_at: nil, deck: @deck)
        return existing if existing
      end
      ls = LearnSession.build_for(
        deck:          @deck,
        user:          @user,
        flashcard_ids: @flashcard_ids,
        limit:         @deck.learn_new_cards_limit
      )
      ls.save!
      ls
    end
  end
end
