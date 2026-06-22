class NotificationPolicy < ApplicationPolicy
  def index?         = true
  def mark_read?     = record.recipient_id == user.id
  def mark_all_read? = true

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.where(recipient: user)
  end
end
