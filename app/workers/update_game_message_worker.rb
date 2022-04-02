class UpdateGameMessageWorker < ApplicationWorker
  def perform(game_id, response_url)
    return if game_id.blank? || response_url.blank?
    game = Game.find(game_id)
    game.replace_message(response_url)
  end
end
