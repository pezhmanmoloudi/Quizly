module DeckPresentationHelper
  # Number of cover color variants defined in CSS (.deck-cover--c0 … --c5).
  DECK_COVER_VARIANTS = 6

  # Curated, unambiguous language → flag emoji map. Languages whose flag would be
  # ambiguous (e.g. English, Arabic) are intentionally omitted — no flag is shown.
  LANGUAGE_FLAGS = {
    "de" => "🇩🇪", "fr" => "🇫🇷", "es" => "🇪🇸", "it" => "🇮🇹", "pt" => "🇵🇹",
    "ru" => "🇷🇺", "ja" => "🇯🇵", "ko" => "🇰🇷", "zh" => "🇨🇳", "fa" => "🇮🇷",
    "tr" => "🇹🇷", "nl" => "🇳🇱", "pl" => "🇵🇱", "sv" => "🇸🇪", "uk" => "🇺🇦",
    "el" => "🇬🇷", "he" => "🇮🇱", "hi" => "🇮🇳", "th" => "🇹🇭", "vi" => "🇻🇳"
  }.freeze

  # Deterministic color variant class, stable per deck.
  def deck_cover_class(deck)
    "deck-cover--c#{deck.id.to_i % DECK_COVER_VARIANTS}"
  end

  # Short representative label for the cover tile: the first card's term when
  # available, otherwise the deck name's leading initials.
  def deck_cover_text(deck)
    term = deck.flashcards.first&.front_content
    text = term.present? ? strip_tags(term).strip : deck.name.to_s
    text = deck.name.to_s if text.blank?
    truncate(text, length: 6, omission: "")
  end

  # Flag emoji for the deck's term language, or nil when unmapped/blank.
  def deck_flag(deck)
    LANGUAGE_FLAGS[deck.term_language.to_s]
  end
end
