class Game < ApplicationRecord
  belongs_to :team
  has_many :answers, dependent: :destroy

  validates :category, presence: true
  validates :question, presence: true
  validates :answer, presence: true
  validates :value, presence: true
  validates :air_date, presence: true
end
