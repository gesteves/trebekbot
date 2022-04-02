Rails.application.routes.draw do
  get  "/success"            => "home#success",       :as => "success"

  # Defines the root path route ("/")
  root "home#index"
end
