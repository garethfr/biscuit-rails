Biscuit::Engine.routes.draw do
  post   "/consent", to: "consent#update"
  delete "/consent", to: "consent#destroy"
end
