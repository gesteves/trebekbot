class Answer < ApplicationRecord
  belongs_to :game
  belongs_to :user

  validates :answer, presence: true

  before_save :check_correctness
  after_commit :update_game

  QUESTION_REGEX = /^(what|where|when|who)/i

  # Returns an emoji representing if the answer is correct or not.
  def emoji
    is_correct? ? ":white_check_mark:" : ":x:"
  end

  # Determines if the text of answer is correct (setting aside if it was expressed as a question).
  # This:
  # 1. Normalizes the submitted answer and the correct answer to remove question words,
  # punctuation, question marks, etc.
  # 2. Removes words in parentheses from the correct answer (so we consider them optional)
  # 3. Splits the correct answer if it contains "or" so we can compare the submitted answer
  # with both parts separately
  # 4. Prepares an array with all these options (correct answer, correct answer without parentheticals, 
  # and the correct answer split by "or")
  # 5. Compares the submitted answer to each of the possible correct answers in the array using a
  # White similarity algorithm (http://www.catalysoft.com/articles/StrikeAMatch.html) to account for typos
  #
  # The submitted answer is correct if it exactly matches any of the correct answers, or if the
  # similarity score with any of them is higher than 0.5
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

  # Simply checks if the submitted answer was formatted in the form of a question.
  # TODO: Might want to use the same white similarity algorithm to account for typos
  # e.g. "wat is" instead of "what is"
  def is_in_question_format?
    answer.strip.match? QUESTION_REGEX
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

  # Normalizes text to make it easier to compare,
  # by removing punctuation, question words and marks, etc.
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
