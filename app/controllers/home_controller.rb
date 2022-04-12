class HomeController < ApplicationController
  before_action :set_max_age

  def index
    @teams_count = Team.all.count
    @players_count = User.all.count
    @games_count = Game.all.count
    @noindex = false
  end

  def success
    @noindex = true
  end
end
