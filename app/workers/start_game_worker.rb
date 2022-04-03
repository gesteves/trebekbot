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
    logger.info "New game in channel #{channel_id} in team #{team_id}: “#{question.dig(:category, :title)}” for $#{question[:value]}: “#{question[:question]}” (#{question[:answer]})"
    PostGameMessageWorker.perform_async(game.id)
  end
end
