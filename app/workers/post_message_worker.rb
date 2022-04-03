class PostMessageWorker < ApplicationWorker
  def perform(text, team_id, channel_id, user_id = nil)
    return if team_id.blank?
    team = Team.find_by(slack_id: team_id)
    if user_id.present?
      team.post_ephemeral_message(channel_id: channel_id, user_id: user_id, text: text)
    else
      team.post_message(channel_id: channel_id, text: text)
    end
    logger.info "Sent message to channel #{channel_id} in team #{team_id}"
  end
end
