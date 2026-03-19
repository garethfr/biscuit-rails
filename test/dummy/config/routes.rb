Rails.application.routes.draw do
  mount Biscuit::Engine, at: "/biscuit"

  root to: "home#index"
  get "/reload", to: "home#reload"
end
