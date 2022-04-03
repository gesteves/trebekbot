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

  def post_message(channel_id:, text:, attachments: nil, blocks: nil, thread_ts: nil)
    return if has_invalid_token?
    slack = Slack.new
    response = slack.post_message(access_token: access_token, channel_id: channel_id, text: text, attachments: attachments, blocks: blocks, thread_ts: thread_ts)
    raise response[:error] unless response[:ok]
    logger.info "Message sent to channel #{channel_id}"
    response
  end

  def update_message(ts:, channel_id:, text:, attachments: nil, blocks: nil)
    return if has_invalid_token?
    slack = Slack.new
    response = slack.update_message(access_token: access_token, ts: ts, channel_id: channel_id, text: text, attachments: attachments, blocks: blocks)
    raise response[:error] unless response[:ok]
    logger.info "Updated message #{ts} in channel #{channel_id}"
    response
  end

  def post_ephemeral_message(channel_id:, user_id:, text:, thread_ts: nil)
    return if has_invalid_token?
    slack = Slack.new
    response = slack.post_ephemeral_message(access_token: access_token, channel_id: channel_id, text: text, user_id: user_id, thread_ts: thread_ts)
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

  def top_users(limit: 10)
    users.order('score ASC').limit(limit)
  end

  def post_leaderboard_to_slack(channel_id:)
    blocks = leaderboard_blocks(top_users)
    text = "Top scores"
    response = post_message(channel_id: channel_id, text: text, blocks: blocks)
  end

  private

  def leaderboard_blocks(users)
    blocks = []

    blocks << {
      type: "section",
      text: {
        type: "mrkdwn",
        text: "*Top scores*"
      }
    }

    blocks << {
      "type": "divider"
    }

    if users.present?
      users.each do |user|
        blocks << {
          type: "context",
          elements: [
            {
              type: "image",
              image_url: user.avatar,
              alt_text: user.name
            },
            {
              type: "mrkdwn",
              text: "#{user.name} | *#{user.pretty_score}*",
              emoji: true
            }
          ]
        }
      end
    else
      blocks << {
        type: "context",
        elements: [
          {
            type: "plain_text",
            text: "Nobody has played yet.",
            emoji: true
          }
        ]
      }
    end

    blocks
  end
end
