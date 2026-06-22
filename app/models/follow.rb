class Follow < ApplicationRecord
  belongs_to :follower, class_name: "User", inverse_of: :follows_as_follower
  belongs_to :followed, class_name: "User",
                        counter_cache: :followers_count,
                        inverse_of: :follows_as_followed

  validates :follower_id, uniqueness: { scope: :followed_id, message: :already_following }
  validate :not_self_following

  private

  def not_self_following
    return if follower_id.blank? || followed_id.blank?
    errors.add(:base, :cannot_follow_self) if follower_id == followed_id
  end
end
