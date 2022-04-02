class Team < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :games, dependent: :destroy

  validates :slack_id, presence: true, uniqueness: true
  validates :access_token, presence: true

  INVALID_AUTH_ERRORS = %w{
    invalid_auth
    account_inactive
    token_revoked
    token_expired
  }

  def post_in_channel(channel_id:, text:, attachments: nil, blocks: nil)
    return if has_invalid_token?
    slack = Slack.new
    response = slack.post_message(access_token: access_token, channel_id: channel_id, text: text, attachments: attachments, blocks: blocks)
    raise response[:error] unless response[:ok]
    logger.info "Message sent to channel #{channel_id}"
    response
  end

  def post_ephemeral_message(channel_id:, user_id:, text:)
    return if has_invalid_token?
    slack = Slack.new
    response = slack.post_ephemeral_message(access_token: access_token, channel_id: channel_id, text: text, user_id: user_id)
    raise response[:error] unless response[:ok]
    logger.info "Ephemeral message sent to channel #{channel_id}"
    response
  end

  def has_invalid_token?
    slack = Slack.new
    response = slack.auth_test(access_token: access_token)
    invalid_token = !response[:ok] && INVALID_AUTH_ERRORS.include?(response[:error])
    logger.error "Team #{team_id} has an invalidated token" if invalid_token
    invalid_token
  end
end
