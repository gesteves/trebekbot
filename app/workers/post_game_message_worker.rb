class PostGameMessageWorker < ApplicationWorker
  def perform(game_id)
    return if game_id.blank?
    game = Game.find(game_id)
    game.post_to_slack
    logger.info "Sent message for game #{game.id} to channel #{game.channel} in team #{game.team.slack_id}"
  end
end
