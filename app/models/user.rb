class User < ApplicationRecord
  belongs_to :team
  has_many :answers, dependent: :destroy

  validates :slack_id, presence: true
end
