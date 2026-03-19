module Biscuit
  module BiscuitHelper
    # Renders the consent banner.
    # If consent has already been given, renders only the minimal
    # "Cookie settings" reopener link (hidden banner state).
    def biscuit_banner(**options)
      consent = Biscuit::Consent.new(cookies)
      render partial: "biscuit/banner/banner",
             locals: { consent: consent, options: options }
    end

    # Returns true if the user has consented to the given category.
    # Safe to call even when no cookie exists — returns false.
    def biscuit_allowed?(category)
      Biscuit::Consent.new(cookies).allowed?(category)
    end
  end
end
