class User < ApplicationRecord
  include ActionView::Helpers::NumberHelper
  belongs_to :team
  has_many :answers, dependent: :destroy

  validates :slack_id, presence: true

  def avatar
    Rails.cache.fetch("slack/user/avatar/#{slack_id}", expires_in: 1.day) do
      slack = Slack.new
      response = slack.user_info(access_token: team.access_token, user_id: slack_id)
      return if response.blank?
      raise response[:error] unless response[:ok]
      response.dig(:user, :profile, :image_192).presence || response.dig(:user, :profile, :image_72).presence || response.dig(:user, :profile, :image_48).presence || response.dig(:user, :profile, :image_32).presence || response.dig(:user, :profile, :image_24).presence || response.dig(:user, :profile, :image_original).presence
    end
  end

  def real_name
    Rails.cache.fetch("slack/user/real_name/#{slack_id}", expires_in: 1.day) do
      slack = Slack.new
      response = slack.user_info(access_token: team.access_token, user_id: slack_id)
      return if response.blank?
      raise response[:error] unless response[:ok]
      response.dig(:user, :real_name).presence
    end
  end

  def first_name
    Rails.cache.fetch("slack/user/first_name/#{slack_id}", expires_in: 1.day) do
      slack = Slack.new
      response = slack.user_info(access_token: team.access_token, user_id: slack_id)
      return if response.blank?
      raise response[:error] unless response[:ok]
      response.dig(:user, :profile, :first_name).presence
    end
  end

  def username
    Rails.cache.fetch("slack/user/username/#{slack_id}", expires_in: 1.day) do
      slack = Slack.new
      response = slack.user_info(access_token: team.access_token, user_id: slack_id)
      return if response.blank?
      raise response[:error] unless response[:ok]
      response.dig(:user, :name).presence
    end
  end

  def display_name
    return "test user" if Rails.env.test?
    first_name || real_name || username
  end

  def mention
    "<@#{slack_id}>"
  end

  def add_score(amount)
    self.score += amount
    save!
  end

  def deduct_score(amount)
    self.score -= amount
    save!
  end

  def pretty_score
    number_to_currency(score, precision: 0)
  end

  def correct_answer_message
    ["That is correct, #{display_name}! Your score is now #{pretty_score}.",
     "That’s right, #{display_name}! Your score is now #{pretty_score}.",
     "You got it, #{display_name}! You now have a score of #{pretty_score}."].sample
  end

  def not_a_question_message
    ["That is correct, #{display_name}, but responses must be in the form of a question. Your score is now #{pretty_score}."].sample
  end

  def incorrect_answer_message
    ["That is incorrect, #{display_name}. Your score is now #{pretty_score}.",
     "That isn’t quite right, #{display_name}. Your score is now #{pretty_score}.",
     "Wrong, #{display_name}. Your score is now #{pretty_score}."].sample
  end

  def duplicate_answer_message
   ["You’ve had your chance, #{display_name}. Let somebody else answer.",
    "You already answered this, #{display_name}. Give someone else a chance.",
    "You had a shot already, #{display_name}. Let someone else try."].sample
  end

  def longest_streak
    # https://stackoverflow.com/a/29701996
    answers.order('created_at ASC').pluck(:is_correct).chunk { |a| a }.reject { |a| !a.first }.map { |_, x| x.size }.max.to_i
  end

  def current_streak
    streak = answers.order('created_at DESC').pluck(:is_correct).chunk { |a| a }.first
    return 0 unless streak&.first
    streak.last.size
  end

  def total_answers
    answers.count
  end

  def correct_answers
    answers.where(is_correct: true).count
  end

  def incorrect_answers
    answers.where(is_correct: false).count
  end

  def correct_percentage
    return 0.0 if answers.empty?
    (correct_answers.to_f * 100)/answers.count.to_f
  end
end
