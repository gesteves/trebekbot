class StartGameWorker < ApplicationWorker
  def perform(team_id, channel_id, user_id)
    return if team_id.blank? || channel_id.blank?
    team = Team.find_by(slack_id: team_id)
    return if team.blank?

    q = Jservice.get_question
    question = q[:question]
    answer = q[:answer]
    value = q[:value]
    category = q.dig(:category, :title)
    air_date = q[:airdate]

    game = Game.new(question: question,
                    answer: answer,
                    value: value,
                    category: category,
                    air_date: air_date,
                    channel: channel_id,
                    team: team)
    game.save!
    logger.info "[LOG] [Team #{team_id}] [Channel #{channel_id}] [Game #{game.id}] New game: #{question} | #{answer}"
    PostGameMessageWorker.perform_async(game.id)
    EndGameWorker.perform_in(ENV['CONFIG_GAME_TIME_LIMIT'].to_i.seconds, game.id)
  end
end
