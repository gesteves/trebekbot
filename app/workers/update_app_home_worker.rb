class UpdateAppHomeWorker < ApplicationWorker
  def perform(team_id, user_id)
    return if team_id.blank? || user_id.blank?
    team = Team.find_by(slack_id: team_id)
    return if team.blank?
    user = User.find_or_create_by(team_id: team.id, slack_id: user_id)
    user.update_app_home
  end
end
