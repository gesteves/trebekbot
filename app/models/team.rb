class Team < ApplicationRecord
  include ActionView::Helpers::NumberHelper

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
    return if response.blank?
    raise response[:error] unless response[:ok]
    response
  end

  def update_message(ts:, channel_id:, text:, attachments: nil, blocks: nil)
    return if has_invalid_token?
    slack = Slack.new
    response = slack.update_message(access_token: access_token, ts: ts, channel_id: channel_id, text: text, attachments: attachments, blocks: blocks)
    return if response.blank?
    raise response[:error] unless response[:ok]
    response
  end

  def post_ephemeral_message(channel_id:, user_id:, text:, thread_ts: nil)
    return if has_invalid_token?
    slack = Slack.new
    response = slack.post_ephemeral_message(access_token: access_token, channel_id: channel_id, text: text, user_id: user_id, thread_ts: thread_ts)
    return if response.blank?
    raise response[:error] unless response[:ok]
    response
  end

  def update_app_home(user_id:, view:)
    return if has_invalid_token?
    slack = Slack.new
    response = slack.views_publish(access_token: access_token, user_id: user_id, view: view)
    return if response.blank?
    raise response[:error] unless response[:ok]
    response
  end

  def has_invalid_token?
    slack = Slack.new
    response = slack.auth_test(access_token: access_token)
    invalid_token = !response[:ok] && INVALID_AUTH_ERRORS.include?(response[:error])
    logger.error "[LOG] [Team #{team_id}] Invalid token" if invalid_token
    invalid_token
  end

  def top_users(limit: 100)
    users.order('score DESC').limit(limit)
  end

  def bot_user_id
    Rails.cache.fetch("slack/bot/user_id/#{bot_id}", expires_in: 1.day) do
      slack = Slack.new
      response = slack.bot_info(access_token: team.access_token, bot_id: bot_id)
      return if response.blank?
      raise response[:error] unless response[:ok]
      response.dig(:user, :id).presence
    end
  end

  def bot_name
    Rails.cache.fetch("slack/bot/real_name/#{bot_id}", expires_in: 1.day) do
      slack = Slack.new
      response = slack.bot_info(access_token: team.access_token, bot_id: bot_id)
      return if response.blank?
      raise response[:error] unless response[:ok]
      response.dig(:user, :real_name).presence
    end
  end

  def bot_mention
    "<@#{bot_user_id}>"
  end

  def post_leaderboard_to_slack(channel_id:, thread_ts: nil)
    text = "Let’s take a look at the top scores:"
    blocks = to_leaderboard_blocks(title: text, limit: 10)
    response = post_message(channel_id: channel_id, text: text, blocks: blocks, thread_ts: thread_ts)
  end

  def to_leaderboard_blocks(title:, limit: 10)
    users = top_users(limit: limit)
    blocks = []

    blocks << {
      type: "section",
      text: {
        type: "mrkdwn",
        text: "*#{title}*"
      }
    }

    if users.present?
      users.each do |user|
        text = "#{user.real_name || user.username} | *#{user.pretty_score}* | Answers: *#{user.total_answers}* | Correct: *#{number_to_percentage(user.correct_percentage, precision: 0)}*"
        text += " | Longest streak: *#{user.longest_streak}*" if user.longest_streak > 1
        text += " | Current streak: *#{user.current_streak}*" if user.current_streak > 1
        blocks << {
          type: "context",
          elements: [
            {
              type: "image",
              image_url: user.avatar,
              alt_text: user.display_name
            },
            {
              type: "mrkdwn",
              text: text
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
