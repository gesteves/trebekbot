class Answer < ApplicationRecord
  belongs_to :game
  belongs_to :user

  validates :answer, presence: true

  before_save :check_correctness
  after_commit :update_game

  QUESTION_REGEX = /^(what|where|when|who)/i

  def emoji
    is_correct? ? ":white_check_mark:" : ":x:"
  end

  def is_answer_correct?
    # Remove cruft from the correct and user-entered answers
    sanitized_answer = normalize_answer(answer)
    correct_answer = normalize_answer(game.answer)

    # Consider text in parentheses as optional
    without_parentheses = correct_answer.gsub(/\(.*\)/, "")

    # Consider answers with "or" as separate options
    or_answers = correct_answer.split(' or ')

    # Build an array with all the potentially correct answers
    possible_correct_answers = [correct_answer, without_parentheses, or_answers].flatten.uniq

    white = Text::WhiteSimilarity.new

    # The answer is correct if it's exactly one of the possible answers,
    # or it has a similarity score > the threshold with any of the possible answers
    possible_correct_answers.any? { |a| sanitized_answer == a || white.similarity(sanitized_answer, a) > ENV['CONFIG_ANSWER_SIMILARITY_THRESHOLD'].to_f }
  end

  def is_in_question_format?
    answer.strip.match? QUESTION_REGEX
  end

  private

  def check_correctness
    self.is_correct = is_in_question_format? && is_answer_correct?
  end

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

  def normalize_answer(text)
    text.gsub(QUESTION_REGEX, "")
        .gsub(/['"“”‘’_-]/, "")
        .gsub(/^\s*+(is|are|was|were|s) /, "")
        .gsub(/^\s*+(the|a|an) /i, "")
        .gsub(/\s+(&amp;|&)\s+/i, " and ")
        .gsub(/\?+$/, "")
        .strip
        .downcase
  end
end
