class DeckDuplicator
  def self.call(source_deck:, user:, name: nil, visibility: "private", access_mode: "open")
    new(source_deck:, user:, name:, visibility:, access_mode:).call
  end

  def initialize(source_deck:, user:, name: nil, visibility: "private", access_mode: "open")
    @source_deck = source_deck
    @user        = user
    @name        = name.presence || source_deck.name
    @visibility  = Deck::VISIBILITY_VALUES.include?(visibility) ? visibility : "private"
    @access_mode = Deck::ACCESS_MODE_VALUES.include?(access_mode) ? access_mode : "open"
  end

  def call
    ActiveRecord::Base.transaction do
      copy = Deck.create!(
        user:          @user,
        name:          @name,
        description:   @source_deck.description,
        subject_tags:  @source_deck.subject_tags,
        language_code: @source_deck.language_code,
        access_mode:   @access_mode,
        visibility:    @visibility,
        source_deck:   @source_deck
      )
      @source_deck.flashcards.each do |card|
        copy.flashcards.create!(
          front_content:  card.front_content,
          back_content:   card.back_content,
          position:       card.position,
          front_language: card.front_language,
          back_language:  card.back_language
        )
      end
      copy
    end
  end
end
