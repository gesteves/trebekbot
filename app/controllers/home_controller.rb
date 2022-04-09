class HomeController < ApplicationController
  def index
    @noindex = false
  end

  def success
    @noindex = true
  end
end
