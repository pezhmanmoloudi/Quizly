class FolderPolicy < ApplicationPolicy
  def create?      = user.present?
  def update?      = owner?
  def destroy?     = owner?
  def add_deck?    = owner?
  def remove_deck? = owner?

  private

  def owner? = user.present? && record.user_id == user.id
end
