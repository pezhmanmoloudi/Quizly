class FollowPolicy < ApplicationPolicy
  # create?: authenticated user who is not following themselves.
  def create?  = user.present? && record.followed_id != user.id

  # destroy?: only the follower can remove their own follow record.
  def destroy? = user.present? && record.follower_id == user.id

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.where(follower: user)
  end
end
