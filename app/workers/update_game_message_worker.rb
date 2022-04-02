class UpdateGameMessageWorker < ApplicationWorker
  def perform(game_id, response_url)
    return if game_id.blank? || response_url.blank?
    game = Game.find(game_id)
    game.replace_message(response_url)
    logger.info "Updated message for game #{game.id} in channel #{game.channel} in team #{game.team.slack_id}"
  end
end
