Rails.application.routes.draw do
  require "sidekiq/web"
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(username), ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_USERNAME"])) &
    ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(password), ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_PASSWORD"]))
  end if ENV["SIDEKIQ_USE_BASIC_AUTH"].present?
  mount Sidekiq::Web, at: "/sidekiq"
  # Slack endpoints
  get  "/slack/auth"         => "slack#auth",         :as => "auth"
  post "/slack/interactions" => "slack#interactions", :as => "interactions"
  post "/slack/events"       => "slack#events",       :as => "events"

  # Pages
  get "/success" => "home#success", :as => "success"
  get "/privacy" => "home#privacy", :as => "privacy"
  root "home#index"
end
