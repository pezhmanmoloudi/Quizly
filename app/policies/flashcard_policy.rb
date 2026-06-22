class FlashcardPolicy < ApplicationPolicy
  def create?      = owner_of_deck?
  def update?      = owner_of_deck?
  def destroy?     = owner_of_deck?
  def restore?     = owner_of_deck?
  def purge_image? = owner_of_deck?

  private

  def owner_of_deck? = user.present? && record.deck.user_id == user.id
end
