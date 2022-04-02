class Answer < ApplicationRecord
  belongs_to :game
  belongs_to :user

  validates :answer, presence: true
end
