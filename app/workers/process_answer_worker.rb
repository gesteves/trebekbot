class ProcessAnswerWorker < ApplicationWorker
  def perform(team_id, channel_id, ts, user_id, answer, response_url)
    return if team_id.blank? || channel_id.blank? || ts.blank? || user_id.blank? || answer.blank? || response_url.blank?

    team = Team.find_by(slack_id: team_id)
    game = team.games.find_by(channel: channel_id, ts: ts)
    if game.has_correct_answer?
      game.send_ephemeral_message(text: "Sorry, someone already answered!", url: response_url)
      return
    end
    user = User.find_or_create_by(team_id: team.id, slack_id: user_id)
    logger.info "Received answer “#{answer}“ for game #{game.id} from user #{user.slack_id} in channel #{channel_id} in team #{team_id}"

    answer = Answer.find_by(game: game, user: user)

    if answer.present?
      game.send_ephemeral_message(text: "You’ve already submitted an answer!", url: response_url)
    else
      answer = Answer.new(game: game, user: user, answer: answer)
      answer.save!
      UpdateGameMessageWorker.perform_async(game.id, response_url)
    end
  end
end
