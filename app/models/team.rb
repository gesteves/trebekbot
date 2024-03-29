class Team < ApplicationRecord
  include ActionView::Helpers::NumberHelper

  has_many :users, -> { order 'score DESC' }, dependent: :destroy
  has_many :games, -> { order 'created_at DESC' }, dependent: :destroy

  validates :slack_id, presence: true, uniqueness: true
  validates :access_token, presence: true

  INVALID_AUTH_ERRORS = %w{
    invalid_auth
    account_inactive
    token_revoked
    token_expired
  }

  def post_message(channel_id:, text:, attachments: nil, blocks: nil, thread_ts: nil)
    slack = Slack.new
    response = slack.post_message(access_token: access_token, channel_id: channel_id, text: text, attachments: attachments, blocks: blocks, thread_ts: thread_ts)
    return if response.blank?
    raise response[:error] unless response[:ok]
    response
  end

  def update_message(ts:, channel_id:, text:, attachments: nil, blocks: nil)
    slack = Slack.new
    response = slack.update_message(access_token: access_token, ts: ts, channel_id: channel_id, text: text, attachments: attachments, blocks: blocks)
    return if response.blank?
    raise response[:error] unless response[:ok]
    response
  end

  def post_ephemeral_message(channel_id:, user_id:, text:, thread_ts: nil)
    slack = Slack.new
    response = slack.post_ephemeral_message(access_token: access_token, channel_id: channel_id, text: text, user_id: user_id, thread_ts: thread_ts)
    return if response.blank?
    raise response[:error] unless response[:ok]
    response
  end

  def update_app_home(user_id:, view:)
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
    users.limit(limit).select { |u| u.has_played? }
  end

  def bot_id
    return if Rails.env.test?
    Rails.cache.fetch("slack/#{slack_id}/bot/id/", expires_in: 1.day) do
      slack = Slack.new
      response = slack.auth_test(access_token: access_token)
      return if response.blank?
      raise response[:error] unless response[:ok]
      response.dig(:bot_id).presence
    end
  end

  def bot_user_id
    return if Rails.env.test?
    Rails.cache.fetch("slack/#{slack_id}/bot/user_id/", expires_in: 1.day) do
      slack = Slack.new
      response = slack.bot_info(access_token: access_token, bot_id: bot_id)
      return if response.blank?
      raise response[:error] unless response[:ok]
      response.dig(:bot, :user_id).presence
    end
  end

  def bot_name
    return if Rails.env.test?
    Rails.cache.fetch("slack/#{slack_id}/bot/real_name/", expires_in: 1.day) do
      slack = Slack.new
      response = slack.bot_info(access_token: access_token, bot_id: bot_id)
      return if response.blank?
      raise response[:error] unless response[:ok]
      response.dig(:bot, :name).presence
    end
  end

  def name
    return if Rails.env.test?
    Rails.cache.fetch("slack/team/name/#{slack_id}", expires_in: 1.day) do
      slack = Slack.new
      response = slack.auth_test(access_token: access_token)
      return if response.blank?
      raise response[:error] unless response[:ok]
      response.dig(:team).presence
    end
  end

  def bot_mention
    "<@#{bot_user_id}>"
  end

  def post_scoreboard_to_slack(channel_id:, thread_ts: nil)
    text = "Here are the top scores for #{name}:"
    blocks = ScoreboardPresenter.new(self).to_blocks(limit: 10)
    response = post_message(channel_id: channel_id, text: text, blocks: blocks, thread_ts: thread_ts)
  end
end
