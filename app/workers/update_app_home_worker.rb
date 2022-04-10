class UpdateAppHomeWorker < ApplicationWorker
  def perform(team_id, user_id)
    return if team_id.blank? || user_id.blank?
    team = Team.find_by(slack_id: team_id)
    return if team.blank?
    user = team.users.find_by(slack_id: user_id)
    return if user.blank?

    user.update_app_home
  end
end
