class User < ApplicationRecord
  include ActionView::Helpers::NumberHelper
  belongs_to :team
  has_many :answers, dependent: :destroy

  validates :slack_id, presence: true

  def avatar
    slack = Slack.new
    response = slack.user_info(access_token: team.access_token, user_id: slack_id)
    raise response[:error] unless response[:ok]
    response.dig(:user, :profile, :image_192).presence || response.dig(:user, :profile, :image_72).presence || response.dig(:user, :profile, :image_48).presence || response.dig(:user, :profile, :image_32).presence || response.dig(:user, :profile, :image_24).presence || response.dig(:user, :profile, :image_original).presence
  end

  def name
    slack = Slack.new
    response = slack.user_info(access_token: team.access_token, user_id: slack_id)
    raise response[:error] unless response[:ok]
    response.dig(:user, :real_name).presence || response.dig(:user, :name).presence
  end

  def add_score(amount)
    logger.info "Adding #{number_to_currency(amount, precision: 0)} to user #{slack_id}"
    self.score += amount
    save!
  end

  def deduct_score(amount)
    logger.info "Deducting #{number_to_currency(amount, precision: 0)} from user #{slack_id}"
    self.score -= amount
    save!
  end

  def pretty_score
    number_to_currency(score, precision: 0)
  end
end
