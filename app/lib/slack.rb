class Slack
  def initialize
    @client_id = ENV['SLACK_CLIENT_ID']
    @client_secret = ENV['SLACK_CLIENT_SECRET']
  end

  # Exchanges a temporary OAuth verifier code for an access token.
  # @param code [String] A temporary authorization code granted by OAuth
  # @param redirect_uri [String] The redirect URI specified in the initial auth request
  # @see https://api.slack.com/methods/oauth.v2.access
  # @return [String] A JSON response.
  def get_access_token(code:, redirect_uri: nil)
    query = {
      code: code,
      client_id: @client_id,
      client_secret: @client_secret,
      redirect_uri: redirect_uri
    }.compact
    response = HTTParty.get("https://slack.com/api/oauth.v2.access", query: query)
    JSON.parse(response.body, symbolize_names: true)
  end

  # Checks authentication & identity.
  # @param access_token [String] Authentication token bearing required scopes.
  # @see https://api.slack.com/methods/auth.test
  # @return [String] A JSON response.
  def auth_test(access_token:)
    response = HTTParty.post("https://slack.com/api/auth.test", headers: { 'Authorization': "Bearer #{access_token}" })
    JSON.parse(response.body, symbolize_names: true)
  end

  # Sends a message to a channel.
  # @param access_token [String] Authentication token bearing required scopes.
  # @param channel_id [String] Channel, private group, or IM channel to send message to.
  # @param attachments [Hash] The content of the message.
  # @param blocks [Hash] The content of the message.
  # @param text [String] The content of the message. If `attachments`` or `blocks`` are included, `text`` will be used as fallback text for notifications only.
  # @param link_names [Boolean] Find and link channel names and usernames.
  # @param markdown [Boolean] Disable Slack markup parsing by setting to false.
  # @param parse [String] Change how messages are treated, can be `none` or `full`.
  # @param reply_broadcast [Boolean] Used in conjunction with `thread_ts`` and indicates whether reply should be made visible to everyone in the channel or conversation.
  # @param thread_ts [String] Provide another message's ts value to make this message a reply.
  # @param unfurl_links [Boolean] Pass true to enable unfurling of primarily text-based content
  # @param unfurl_media [Boolean] Pass false to disable unfurling of media content.
  # @see https://api.slack.com/methods/chat.postMessage
  # @return [String] A JSON response.
  def post_message(
    access_token:,
    channel_id:,
    attachments: nil,
    blocks: nil,
    text: nil,
    link_names: true,
    markdown: true,
    parse: 'none',
    reply_broadcast: false,
    thread_ts: nil,
    unfurl_links: true,
    unfurl_media: true
  )
    return if attachments.blank? && blocks.blank? && text.blank?
    params = {
      channel: channel_id,
      attachments: attachments,
      blocks: blocks,
      text: text,
      link_names: link_names,
      mrkdwn: markdown,
      parse: parse,
      reply_broadcast: false,
      thread_ts: thread_ts,
      unfurl_links: true,
      unfurl_media: true
    }.compact
    response = HTTParty.post("https://slack.com/api/chat.postMessage",
                            body: params.to_json,
                            headers: { 'Authorization': "Bearer #{access_token}", 'Content-Type': 'application/json' })
    JSON.parse(response.body, symbolize_names: true)
  end

  # Updates a message.
  # @param access_token [String] Authentication token bearing required scopes.
  # @param channel_id [String] Channel containing the message to be updated.
  # @param ts [String] Timestamp of the message to be updated.
  # @param attachments [Hash] The content of the message.
  # @param blocks [Hash] The content of the message.
  # @param text [String] The content of the message. If `attachments`` or `blocks`` are included, `text`` will be used as fallback text for notifications only.
  # @param link_names [Boolean] Find and link channel names and usernames.
  # @param parse [String] Change how messages are treated, can be `none` or `full`.
  # @param reply_broadcast [Boolean] Used in conjunction with `thread_ts`` and indicates whether reply should be made visible to everyone in the channel or conversation.
  # @see https://api.slack.com/methods/chat.postMessage
  # @return [String] A JSON response.
  def update_message(
    access_token:,
    channel_id:,
    ts:,
    attachments: nil,
    blocks: nil,
    text: nil,
    link_names: true,
    parse: 'none',
    reply_broadcast: false
  )
    return if attachments.blank? && blocks.blank? && text.blank?
    params = {
      channel: channel_id,
      ts: ts,
      attachments: attachments,
      blocks: blocks,
      text: text,
      link_names: link_names,
      parse: parse,
      reply_broadcast: false
    }.compact
    response = HTTParty.post("https://slack.com/api/chat.update",
                            body: params.to_json,
                            headers: { 'Authorization': "Bearer #{access_token}", 'Content-Type': 'application/json' })
    JSON.parse(response.body, symbolize_names: true)
  end

  # Sends an ephemeral message to a user in a channel.
  # @param access_token [String] Authentication token bearing required scopes.
  # @param channel_id [String] Channel, private group, or IM channel to send message to.
  # @param user_id [String] id of the user who will receive the ephemeral message. The user should be in the channel specified by the channel argument.
  # @param attachments [Hash] The content of the message.
  # @param blocks [Hash] The content of the message.
  # @param text [String] The content of the message. If `attachments`` or `blocks`` are included, `text`` will be used as fallback text for notifications only.
  # @param link_names [Boolean] Find and link channel names and usernames.
  # @param parse [String] Change how messages are treated, can be `none` or `full`.
  # @param thread_ts [String] Provide another message's ts value to make this message a reply.
  # @see https://api.slack.com/methods/chat.postMessage
  # @return [String] A JSON response.
  def post_ephemeral_message(
    access_token:,
    channel_id:,
    user_id:,
    text:,
    attachments: nil,
    blocks: nil,
    link_names: true,
    parse: 'none',
    thread_ts: nil
  )
    return if attachments.blank? && blocks.blank? && text.blank?
    params = {
      channel: channel_id,
      attachments: attachments,
      blocks: blocks,
      text: text,
      user: user_id,
      link_names: link_names,
      parse: parse,
      thread_ts: thread_ts
    }.compact
    response = HTTParty.post("https://slack.com/api/chat.postEphemeral",
                            body: params.to_json,
                            headers: { 'Authorization': "Bearer #{access_token}", 'Content-Type': 'application/json' })
    JSON.parse(response.body, symbolize_names: true)
  end

  # Gets information about a user.
  # @param access_token [String] Authentication token bearing required scopes.
  # @param user_id [String] User to get info on
  # @see https://api.slack.com/methods/users.info
  # @return [String] A JSON response.
  def user_info(access_token:, user_id:)
    query = {
      user: user_id
    }.compact
    response = HTTParty.get("https://slack.com/api/users.info",
                            query: query,
                            headers: { 'Authorization': "Bearer #{access_token}" })
    JSON.parse(response.body, symbolize_names: true)
  end
end
