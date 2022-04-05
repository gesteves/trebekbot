class StartGameWorker < ApplicationWorker
  def perform(team_id, channel_id)
    return if team_id.blank? || channel_id.blank?
    team = Team.find_by(slack_id: team_id)
    return if team.blank?

    question = Jservice.get_question
    game = Game.new(question: question[:question],
                    answer: question[:answer],
                    value: question[:value],
                    category: question.dig(:category, :title),
                    air_date: question[:airdate],
                    channel: channel_id,
                    team: team)
    game.save!
    logger.info "[LOG] [Team #{team_id}] [Channel #{channel_id}] [Game #{game.id}] New game: #{question.dig(:category, :title)} | $#{question[:value]} | #{question[:question]} | #{question[:answer]}"
    PostGameMessageWorker.perform_async(game.id)
    EndGameWorker.perform_in(5.minutes, game.id)
  end
end
