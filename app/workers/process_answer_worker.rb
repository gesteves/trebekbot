class ProcessAnswerWorker < ApplicationWorker
  def perform(team_id, channel_id, ts, user_id, user_answer)
    return if team_id.blank? || channel_id.blank? || ts.blank? || user_id.blank? || user_answer.blank?

    team = Team.find_by(slack_id: team_id)
    game = team.games.find_by(channel: channel_id, ts: ts)
    user = User.find_or_create_by(team_id: team.id, slack_id: user_id)

    logger.info "[LOG] [Team #{team_id}] [Channel #{channel_id}] [Game #{game.id}] [User #{user_id}] Received answer: #{user_answer}"

    return if game.is_closed?

    if game.has_answer_by_user?(user)
      PostMessageWorker.perform_async(user.duplicate_answer_message, team.slack_id, game.channel, game.ts)
    else
      answer = Answer.new(game: game, user: user, answer: user_answer)
      answer.save!
    end
  end
end
