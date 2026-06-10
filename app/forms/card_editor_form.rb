class CardEditorForm
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :rows, :requires_language

  validate :all_rows_complete

  private

  def all_rows_complete
    Array(rows).each_with_index do |row, i|
      n = i + 1
      errors.add(:base, I18n.t("decks.cards.error_term", row: n))       if row[:front_content].blank?
      errors.add(:base, I18n.t("decks.cards.error_definition", row: n)) if row[:back_content].blank?
      next unless requires_language

      errors.add(:base, I18n.t("decks.cards.error_language", row: n, side: I18n.t("decks.card_row.front_label"))) if row[:front_language].blank?
      errors.add(:base, I18n.t("decks.cards.error_language", row: n, side: I18n.t("decks.card_row.back_label")))  if row[:back_language].blank?
    end
  end
end
