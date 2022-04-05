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
    correct_answer = normalize_answer(game.answer)
    sanitized_answer = normalize_answer(answer)

    # Consider text in parentheses as optional
    without_parentheses = sanitized_answer.gsub(/\(.*\)/, "")

    # Consider answers with "or" as separate options
    or_answers = sanitized_answer.split(' or ')

    # Build all array with all the potential answers submitted
    all_answers = [sanitized_answer, without_parentheses, or_answers].flatten.uniq

    white = Text::WhiteSimilarity.new

    # The answer is correct if any of them has a similarity score > 0.5
    all_answers.any? { |a| white.similarity(correct_answer, a) > 0.5 }
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
        .gsub(/['"“”‘’]/, "")
        .gsub(/^\s*+(is|are|was|were|s) /, "")
        .gsub(/^\s*+(the|a|an) /i, "")
        .gsub(/\s+(&amp;|&)\s+/i, " and ")
        .gsub(/\?+$/, "")
        .strip
        .downcase
  end
end
