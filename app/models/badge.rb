class Badge < ApplicationRecord
  has_many :user_badges, dependent: :destroy
  has_many :users, through: :user_badges

  validates :key,         presence: true, uniqueness: true
  validates :name,        presence: true
  validates :description, presence: true
  validates :icon,        presence: true
  validates :category,    presence: true, inclusion: { in: %w[streak cards accuracy] }

  def self.preview_for(user)
    user.badges.order("user_badges.earned_at DESC").limit(3)
  end
end
