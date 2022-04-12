class Answer < ApplicationRecord
  include Textable

  belongs_to :game
  belongs_to :user

  validates :answer, presence: true

  before_save :check_correctness
  after_commit :update_game, if: :saved_change_to_answer?


  # Returns an emoji representing if the answer is correct or not.
  def to_emoji
    is_correct? ? ":white_check_mark:" : ":x:"
  end

  def to_unicode
    is_correct? ? '✔︎' : '✗'
  end

  def normalized_answer
    normalize(answer)
  end

  # The submitted answer is correct if it exactly matches any of the game's accepted answers, or if the
  # similarity score with any of them is higher than 0.5
  def is_answer_correct?
    game.accepted_answers.include?(normalized_answer) || similarity_score > 0.5
  end

  # Returns the best similarity score between the normlized, user-submitted answer,
  # and the answers accepted by the game
  def similarity_score
    white = Text::WhiteSimilarity.new
    normalized = normalized_answer
    game.accepted_answers.map { |a| white.similarity(normalized, a) }.reject(&:nan?).max.to_f
  end

  # Simply checks if the submitted answer was formatted in the form of a question.
  def is_in_question_format?
    is_question? answer
  end

  def debug
    "#{to_unicode} #{user.username} | #{answer} | #{similarity_score.round(3)}"
  end

  private

  # Check if the submitted answer is correct and was formatted as a question.
  def check_correctness
    self.is_correct = is_in_question_format? && is_answer_correct?
  end

  # Updates the game after committing the answer:
  # 1. If the answer is correct and formatted as a question,
  # credits the user with the score, and closes the game.
  # 2. If the answer is correct but not in the form of a question,
  # deducts the score from the user, and closes the game.
  # 3. Otherwise, deducts the score from the user.
  # Afterwards, enqueues an update to the game's message,
  # and notifications to the player.
  def update_game
    if is_answer_correct? && is_in_question_format?
      user.add_score(game.value)
      user.reload
      message = user.correct_answer_message
      game.close!
    elsif is_answer_correct? && !is_in_question_format?
      user.deduct_score(game.value)
      user.reload
      message = user.not_a_question_message
      game.close!
    else
      user.deduct_score(game.value)
      user.reload
      message = user.incorrect_answer_message
    end
    UpdateGameMessageWorker.perform_async(game.id)
    PostMessageWorker.perform_async(message, game.team.slack_id, game.channel, game.ts)
  end
end
