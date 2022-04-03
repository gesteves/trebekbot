class PostLeaderboardWorker < ApplicationWorker
  def perform(team_id, channel_id)
    return if team_id.blank? || channel_id.blank?
    team = Team.find_by(slack_id: team_id)
    return if team.blank?

    team.post_leaderboard_to_slack(channel_id: channel_id)
  end
end
