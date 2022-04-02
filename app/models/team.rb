class Team < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :games, dependent: :destroy

  validates :slack_id, presence: true, uniqueness: true
  validates :access_token, presence: true
end
