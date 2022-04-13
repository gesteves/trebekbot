class Game < ApplicationRecord
  include ActionView::Helpers::NumberHelper
  include Textable

  belongs_to :team
  has_many :answers, -> { order 'created_at DESC' }, dependent: :destroy

  validates :category, presence: true
  validates :question, presence: true
  validates :answer, presence: true
  validates :value, presence: true
  validates :air_date, presence: true

  after_commit :enqueue_message_update, if: :saved_change_to_is_closed?
  after_commit :send_closed_message, if: :saved_change_to_is_closed?

  # Posts the game to Slack, and stores the resulting message's timestamp (ts)
  # so it can be looked up later.
  def post_to_slack
    blocks = GamePresenter.new(self).to_blocks
    text = "The category is #{category}, for $#{value}: “#{question}”"
    response = team.post_message(channel_id: channel, text: text, blocks: blocks)
    self.ts = response.dig(:message, :ts)
    self.save!
  end

  # Updates the message posted for a game, when an answer is submitted or the game is closed.
  def update_message
    return if team.has_invalid_token?
    blocks = GamePresenter.new(self).to_blocks
    text = "The category is #{category}, for $#{value}: “#{question}”"
    response = team.update_message(ts: ts, channel_id: channel, text: text, blocks: blocks)
  end

  # Posts debug information about the game to Slack.
  def post_debug_to_slack
    response = team.post_message(channel_id: channel, text: GamePresenter.new(self).debug, thread_ts: ts)
  end

  # Closes the game, which shows the correct answer and prevents players from submitting more answers.
  def close!
    self.is_closed = true
    save!
  end

  # Returns if any of the answers submitted for this game is correct.
  def is_answered?
    answers.where(is_correct: true).count > 0
  end

  # Returns if the given user has submitted an answer for this game.
  def has_answer_by_user?(user)
    answers.where(user: user).present?
  end

  def is_stumper?
    is_closed? && !answered?
  end

  # Returns an array of possibly accepted answers.
  def accepted_answers
    # Remove cruft from the correct answer
    normalized_answer = normalize(answer)

    # Consider text in parentheses as optional
    without_parentheses = normalized_answer.gsub(/\(.*\)/, "")

    # Consider answers with "or" or "/" as separate options
    or_answers = normalized_answer.split(/\s+or\s+|\//)

    # Accept numeric answers as words
    numeric_answer = normalized_answer.to_i.to_words if normalized_answer == normalized_answer.to_i.to_s

    # Build an array with all the accepted answers
    [normalized_answer, without_parentheses, or_answers, numeric_answer].compact.flatten.uniq
  end

  def pretty_value
    number_to_currency(value, precision: 0)
  end

  def wikipedia_url
    Wikipedia.search(answer)
  end

  private

  # Enqueues a background job to update the game's message in Slack.
  def enqueue_message_update
    UpdateGameMessageWorker.perform_async(id)
  end

  def send_closed_message
    return unless is_closed?

    message = []
    message << "Time’s up! The answer is “#{answer}”." unless is_answered?
    message << "Learn more: #{wikipedia_url}" unless wikipedia_url.blank?

    PostMessageWorker.perform_in(5.seconds, message.join("\n\n"), team.slack_id, channel, ts) unless message.blank?
  end
end
