Rails.application.routes.draw do
  get  "/success"            => "home#success",       :as => "success"

  # Slack endpoints
  get  "/slack/auth"         => "slack#auth",         :as => "auth"
  post "/slack/interactions" => "slack#interactions", :as => "interactions"
  post "slack/events"        => "slack#events",       :as => "events"
  # Defines the root path route ("/")
  root "home#index"
end
