class Answer < ApplicationRecord
  belongs_to :game
  belongs_to :user

  validates :answer, presence: true

  def emoji
    is_correct? ? ":white_check_mark:" : ":negative_squared_cross_mark:"
  end
end
