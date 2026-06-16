module Decks
  class TestSessionService
    MAX_QUESTIONS = 20

    def self.find_or_create(deck:, user:, session_id:, flashcards:)
      new(deck:, user:, session_id:, flashcards:).find_or_create
    end

    def initialize(deck:, user:, session_id:, flashcards:)
      @deck       = deck
      @user       = user
      @session_id = session_id
      @flashcards = flashcards
    end

    def find_or_create
      if @session_id
        existing = @user.test_sessions.find_by(id: @session_id, finished_at: nil, deck: @deck)
        return existing if existing
      end
      count     = [ @flashcards.size, MAX_QUESTIONS ].min
      questions = QuestionEngine.generate(flashcards: @flashcards, count: count)
      @user.test_sessions.create!(
        deck:            @deck,
        questions_data:  questions.to_json,
        questions_total: questions.size,
        started_at:      Time.current
      )
    end
  end
end
