class UserPolicy < ApplicationPolicy
  # All profiles are public — no private accounts for MVP.
  def show? = true

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.all
  end
end
