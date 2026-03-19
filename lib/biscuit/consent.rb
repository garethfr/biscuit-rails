module Biscuit
  class Consent
    CURRENT_VERSION = 1

    # cookies: ActionDispatch::Cookies::CookieJar
    def initialize(cookies)
      @cookies = cookies
      @data    = self.class.parse(cookies[Biscuit.configuration.cookie_name])
    end

    # True if a valid consent decision has been recorded.
    def given?
      !@data.nil?
    end

    # True if the user has consented to this category.
    # :necessary always returns true regardless of cookie state.
    def allowed?(category)
      return true if category.to_sym == :necessary
      return false unless given?
      @data.dig("categories", category.to_s) == true
    end

    # Write consent cookie to the jar.
    def self.write(cookies, categories)
      value  = build_value(categories)
      config = Biscuit.configuration
      cookies[config.cookie_name] = {
        value:     value.to_json,
        expires:   config.cookie_expires_days.days.from_now,
        path:      config.cookie_path,
        domain:    config.cookie_domain,
        same_site: config.cookie_same_site,
        httponly:  false   # Must be readable by JS for client-side consent checks
      }
    end

    # Clear the consent cookie.
    def self.clear(cookies)
      cookies.delete(Biscuit.configuration.cookie_name)
    end

    # Build the cookie value hash. Always forces necessary: true.
    def self.build_value(categories)
      cats = categories.transform_keys(&:to_s)
                       .transform_values { |v| v == true || v == "true" }
      cats["necessary"] = true
      { "v" => CURRENT_VERSION, "consented_at" => Time.now.utc.iso8601, "categories" => cats }
    end

    # Parse raw cookie string. Returns nil if blank, invalid JSON, or wrong version.
    def self.parse(raw)
      return nil if raw.blank?
      data = JSON.parse(raw)
      return nil unless data.is_a?(Hash) && data["v"] == CURRENT_VERSION && data["categories"].is_a?(Hash)
      data
    rescue JSON::ParserError
      nil
    end
  end
end
