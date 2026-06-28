# Shared helper for creating a deck with flashcards idempotently.
# Deck is created as "private" first so the completeness_for_sharing
# validation (requires flashcards for public/unlisted) does not fire
# mid-creation. Visibility is applied via update_columns after cards exist.
def seed_deck(owner, name:, description:, visibility:, cards:, **opts)
  deck = owner.decks.find_or_create_by!(name: name) do |d|
    d.description = description
    d.visibility  = "private"
    opts.each { |k, v| d.public_send(:"#{k}=", v) }
  end

  cards.each.with_index(1) do |card, i|
    deck.flashcards.find_or_create_by!(front_content: card[:front]) do |fc|
      fc.back_content = card[:back]
      fc.position     = i
    end
  end

  deck.update_columns(visibility: visibility) unless deck.visibility == visibility
  deck
end
