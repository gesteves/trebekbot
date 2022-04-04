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

  def name
    Rails.cache.fetch("slack/user/name/#{slack_id}", expires_in: 1.day) do
      slack = Slack.new
      response = slack.user_info(access_token: team.access_token, user_id: slack_id)
      return if response.blank?
      raise response[:error] unless response[:ok]
      response.dig(:user, :real_name).presence || response.dig(:user, :name).presence
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
    "That is correct, #{mention}! Your score is now #{pretty_score}."
  end

  def not_a_question_message
    "That is correct, #{mention}, but responses must be in the form of a question. Your score is now #{pretty_score}."
  end

  def incorrect_answer_message
    "That is incorrect, #{mention}. Your score is now #{pretty_score}."
  end

  def duplicate_answer_message
    "You’ve had your chance, #{mention}. Let somebody else answer."
  end
end
