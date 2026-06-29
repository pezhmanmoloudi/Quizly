class Badge < ApplicationRecord
  has_many :user_badges, dependent: :destroy
  has_many :users, through: :user_badges

  validates :key,         presence: true, uniqueness: true
  validates :name,        presence: true
  validates :description, presence: true
  validates :icon,        presence: true
  validates :category,    presence: true, inclusion: { in: %w[streak cards accuracy] }

  def name
    I18n.t("achievements.badges.#{key}.name", default: self[:name])
  end

  def description
    I18n.t("achievements.badges.#{key}.description", default: self[:description])
  end
end
