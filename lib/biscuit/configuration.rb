module Biscuit
  class Configuration
    # Cookie categories. Each key is the category identifier (symbol).
    # :necessary is always present and always true — cannot be disabled by the user.
    # Additional categories are shown to the user and default to opt-out.
    # Each category accepts:
    #   required: true/false  — if true, shown as disabled/checked in the UI
    attr_accessor :categories

    # Name of the browser cookie storing consent state.
    # Default: "biscuit_consent"
    attr_accessor :cookie_name

    # Consent cookie lifetime in days.
    # Default: 365
    attr_accessor :cookie_expires_days

    # Cookie path. Default: "/"
    attr_accessor :cookie_path

    # Cookie domain. nil means current domain. Default: nil
    attr_accessor :cookie_domain

    # SameSite attribute. Default: "Lax"
    attr_accessor :cookie_same_site

    # Banner position: :bottom or :top. Default: :bottom
    attr_accessor :position

    # URL for the "Learn more" / privacy policy link. Default: "#"
    attr_accessor :privacy_policy_url

    def initialize
      @categories = {
        necessary:  { required: true },
        analytics:  { required: false },
        marketing:  { required: false }
      }
      @cookie_name         = "biscuit_consent"
      @cookie_expires_days = 365
      @cookie_path         = "/"
      @cookie_domain       = nil
      @cookie_same_site    = "Lax"
      @position            = :bottom
      @privacy_policy_url  = "#"
    end
  end
end
