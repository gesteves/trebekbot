class HomeController < ApplicationController
  before_action :set_max_age

  def index
    @noindex = false
  end

  def success
    @noindex = true
  end
end
