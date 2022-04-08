class ApplicationController < ActionController::Base
  def default_url_options
    Rails.application.routes.default_url_options
  end
end
