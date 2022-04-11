class PostScoreboardWorker < ApplicationWorker
  def perform(team_id, channel_id, thread_ts = nil)
    return if team_id.blank? || channel_id.blank?
    team = Team.find_by(slack_id: team_id)
    return if team.blank?

    team.post_scoreboard_to_slack(channel_id: channel_id, thread_ts: thread_ts)
  end
end
