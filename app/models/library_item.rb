class LibraryItem < ApplicationRecord
  belongs_to :user
  belongs_to :deck

  validates :deck_id, uniqueness: { scope: :user_id }
  validate  :cannot_save_own_deck

  private

  def cannot_save_own_deck
    return unless user_id.present? && deck&.user_id.present?
    errors.add(:base, :own_deck) if user_id == deck.user_id
  end
end
