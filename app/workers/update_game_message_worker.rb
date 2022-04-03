class UpdateGameMessageWorker < ApplicationWorker
  def perform(game_id)
    return if game_id.blank?
    game = Game.find(game_id)
    game.update_message
  end
end
