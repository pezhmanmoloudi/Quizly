class DeckDuplicator
  def self.call(source_deck:, user:, name: nil, visibility: "private")
    new(source_deck:, user:, name:, visibility:).call
  end

  def initialize(source_deck:, user:, name: nil, visibility: "private")
    @source_deck = source_deck
    @user        = user
    @name        = name.presence || source_deck.name
    @visibility  = Deck::DUPLICATE_VISIBILITIES.include?(visibility) ? visibility : "private"
  end

  def call
    ActiveRecord::Base.transaction do
      copy = Deck.create!(
        user:            @user,
        name:            @name,
        description:     @source_deck.description,
        subject_tags:    @source_deck.subject_tags,
        language_code:   @source_deck.language_code,
        edit_permission: "only_me",
        visibility:      @visibility,
        source_deck:     @source_deck
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
