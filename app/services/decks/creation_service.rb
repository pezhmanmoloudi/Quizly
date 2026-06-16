module Decks
  class CreationService
    def self.call(user:, name:)
      new(user:, name:).call
    end

    def initialize(user:, name:)
      @user = user
      @name = name
    end

    def call
      @user.decks.create!(
        name:        @name,
        visibility:  "private",
        access_mode: "open"
      )
    end
  end
end
