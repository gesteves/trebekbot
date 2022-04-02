class User < ApplicationRecord
  belongs_to :team
  has_many :answers, dependent: :destroy

  validates :slack_id, presence: true

  def avatar
    slack = Slack.new
    response = slack.user_info(access_token: access_token, user_id: message[:user])
    raise response[:error] unless response[:ok]
    response.dig(:user, :profile, :image_192).presence || response.dig(:user, :profile, :image_72).presence || response.dig(:user, :profile, :image_48).presence || response.dig(:user, :profile, :image_32).presence || response.dig(:user, :profile, :image_24).presence || response.dig(:user, :profile, :image_original).presence
  end

  def name
    slack = Slack.new
    response = slack.user_info(access_token: access_token, user_id: message[:user])
    raise response[:error] unless response[:ok]
    response.dig(:user, :real_name).presence || response.dig(:user, :name).presence
  end
end
