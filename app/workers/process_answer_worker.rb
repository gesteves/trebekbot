class ProcessAnswerWorker < ApplicationWorker
  def perform(team_id, channel_id, ts, user_id, answer, response_url)
    return if team_id.blank? || channel_id.blank? || ts.blank? || user_id.blank? || answer.blank? || response_url.blank?

    team = Team.find_by(slack_id: team_id)
    game = Team.games.find_by(channel: channel_id, ts: ts)
    return if game.has_correct_answer?

    user = User.find_or_create_by(team_id: team.id, slack_id: user_id)
    answer = Answer.new(game: game, user: user, answer: answer)
    answer.save!

    UpdateGameMessageWorker.perform_async(game.id, response_url)
  end
end
