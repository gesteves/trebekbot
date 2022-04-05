class EndGameWorker < ApplicationWorker
  def perform(game_id)
    return if game_id.blank?
    game = Game.find(game_id)
    game&.close!
  end
end
