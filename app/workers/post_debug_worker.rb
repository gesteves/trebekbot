class PostLeaderboardWorker < ApplicationWorker
  def perform(team_id, channel_id, ts)
    return if team_id.blank? || channel_id.blank? || ts.blank?
    team = Team.find_by(slack_id: team_id)
    return if team.blank?
    game = team.games.find_by(channel: channel_id, ts: ts)
    return if game.blank?

    game.post_debug_to_slack
  end
end
