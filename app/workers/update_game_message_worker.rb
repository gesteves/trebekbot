class UpdateGameMessageWorker < ApplicationWorker
  def perform(game_id)
    return if game_id.blank?
    game = Game.find(game_id)
    game.update_message
    logger.info "Updated message for game #{game.id} in channel #{game.channel} in team #{game.team.slack_id}"
  end
end
