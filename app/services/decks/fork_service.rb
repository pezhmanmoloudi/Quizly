module Decks
  class ForkService
    def self.call(source_deck:, user:, name: nil)
      new(source_deck:, user:, name:).call
    end

    def initialize(source_deck:, user:, name: nil)
      @source_deck = source_deck
      @user        = user
      @name        = name
    end

    def call
      DeckDuplicator.call(
        source_deck: @source_deck,
        user:        @user,
        name:        @name.presence || @source_deck.name,
        visibility:  "private",
        access_mode: "open"
      )
    end
  end
end
