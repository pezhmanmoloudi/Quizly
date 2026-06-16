class DeckPolicy < ApplicationPolicy
  # Visibility check only — password gate is a controller-level session concern.
  # show? answers: given the deck's visibility, can this user access it at all?
  def show?              = owner? || !record.private?
  def update?            = owner?
  def destroy?           = owner?
  def learn?             = user.present? && show?
  def test?              = user.present? && show?
  def copy?              = user.present? && !owner? && (record.public? || record.unlisted?)
  def manage_access?     = owner?
  def manage_flashcards? = owner?

  class Scope < ApplicationPolicy::Scope
    def resolve
      base = scope.where(visibility: %w[public unlisted])
      user ? base.or(scope.where(user: user)) : base
    end
  end

  private

  def owner? = user.present? && record.user_id == user.id
end
