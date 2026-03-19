module Biscuit
  class ConsentController < ActionController::Base
    protect_from_forgery with: :exception

    def update
      categories = params.require(:categories).permit(
        Biscuit.configuration.categories.keys.map(&:to_s)
      ).to_h
      Biscuit::Consent.write(cookies, categories)
      render json: { ok: true }
    end

    def destroy
      Biscuit::Consent.clear(cookies)
      render json: { ok: true }
    end
  end
end
