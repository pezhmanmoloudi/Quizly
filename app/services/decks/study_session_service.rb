module Decks
  class StudySessionService
    def self.find_or_create(deck:, user:, session_id:, due_count:)
      new(deck:, user:, session_id:, due_count:).find_or_create
    end

    def initialize(deck:, user:, session_id:, due_count:)
      @deck       = deck
      @user       = user
      @session_id = session_id
      @due_count  = due_count
    end

    def find_or_create
      if @session_id
        existing = @user.study_sessions.find_by(id: @session_id, finished_at: nil, deck: @deck)
        if existing
          existing.update_columns(cards_total: @due_count) if @due_count > existing.cards_total
          return existing
        end
      end
      @user.study_sessions.create!(deck: @deck, cards_total: @due_count, started_at: Time.current)
    end
  end
end
