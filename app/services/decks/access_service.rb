module Decks
  class AccessService
    Result = Data.define(:ok?, :error)

    def self.call(deck:, password:, session:)
      new(deck:, password:, session:).call
    end

    def self.unlocked?(deck:, session:)
      session["deck_#{deck.id}_unlocked"] == true
    end

    def initialize(deck:, password:, session:)
      @deck     = deck
      @password = password
      @session  = session
    end

    def call
      return Result.new(ok?: true, error: nil) if already_unlocked?
      return Result.new(ok?: true, error: nil) unless @deck.password_protected?

      if @deck.authenticate_password(@password.to_s)
        @session["deck_#{@deck.id}_unlocked"] = true
        Result.new(ok?: true, error: nil)
      else
        Result.new(ok?: false, error: :invalid_password)
      end
    end

    private

    def already_unlocked?
      @session["deck_#{@deck.id}_unlocked"] == true
    end
  end
end
