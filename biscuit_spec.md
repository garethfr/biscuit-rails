# Biscuit — GDPR Cookie Consent Gem for Rails 8
## Claude Code Specification

---

## Overview

Build a Ruby gem called `biscuit` that provides GDPR-compliant cookie consent management for Ruby on Rails 8+ applications. It renders a configurable bottom/top banner, manages consent state via a browser cookie, exposes a Stimulus controller for interactivity, and supports i18n and CSS custom property theming out of the box.

**Key constraints:**
- Rails 8.0+ only
- Ruby 3.2+
- No asset pipeline (Sprockets) — assets served directly via Propshaft
- JS delivered as a plain ES module, consumed via import maps
- No runtime dependencies beyond Rails itself

---

## Gem Structure

```
biscuit/
├── app/
│   ├── assets/
│   │   ├── javascripts/
│   │   │   └── biscuit/
│   │   │       └── biscuit_controller.js      # Stimulus controller (ES module)
│   │   └── stylesheets/
│   │       └── biscuit/
│   │           └── biscuit.css                # Scoped styles with CSS custom properties
│   ├── controllers/
│   │   └── biscuit/
│   │       └── consent_controller.rb          # Internal API endpoint
│   ├── helpers/
│   │   └── biscuit/
│   │       └── biscuit_helper.rb
│   └── views/
│       └── biscuit/
│           └── banner/
│               └── _banner.html.erb
├── config/
│   ├── locales/
│   │   ├── en.yml
│   │   └── fr.yml
│   └── routes.rb                              # Internal routes
├── lib/
│   ├── biscuit/
│   │   ├── configuration.rb
│   │   ├── consent.rb
│   │   ├── engine.rb
│   │   └── version.rb
│   └── biscuit.rb
├── test/
│   ├── dummy/                                 # Minimal Rails 8 dummy app
│   ├── biscuit/
│   │   ├── configuration_test.rb
│   │   ├── consent_test.rb
│   │   └── helper_test.rb
│   ├── integration/
│   │   └── banner_test.rb
│   └── test_helper.rb
├── biscuit.gemspec
├── Gemfile
└── README.md
```

---

## Gemspec

```ruby
Gem::Specification.new do |spec|
  spec.name        = "biscuit"
  spec.version     = Biscuit::VERSION
  spec.authors     = ["TODO"]
  spec.summary     = "GDPR-compliant cookie consent banner for Rails 8"
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 3.2"

  spec.add_dependency "rails", ">= 8.0"

  spec.files = Dir[
    "app/**/*",
    "config/**/*",
    "lib/**/*",
    "README.md",
    "LICENSE"
  ]
end
```

---

## Configuration

### `lib/biscuit/configuration.rb`

```ruby
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
```

### `lib/biscuit.rb`

```ruby
require "biscuit/version"
require "biscuit/configuration"
require "biscuit/consent"
require "biscuit/engine"

module Biscuit
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
```

Host app initializer (`config/initializers/biscuit.rb`):

```ruby
Biscuit.configure do |config|
  config.categories = {
    necessary:   { required: true },
    analytics:   { required: false },
    preferences: { required: false },
    marketing:   { required: false }
  }
  config.cookie_expires_days = 180
  config.position            = :bottom
  config.privacy_policy_url  = "/privacy"
end
```

---

## Consent Logic

### `lib/biscuit/consent.rb`

Reads and writes consent state from the browser cookie. The cookie value is a JSON string.

**Cookie format:**
```json
{
  "v": 1,
  "consented_at": "2026-03-19T10:00:00Z",
  "categories": {
    "necessary": true,
    "analytics": false,
    "marketing": true
  }
}
```

```ruby
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
```

---

## Rails Engine

### `lib/biscuit/engine.rb`

```ruby
module Biscuit
  class Engine < ::Rails::Engine
    isolate_namespace Biscuit

    # Make helper available in all host app views
    initializer "biscuit.helpers" do
      ActiveSupport.on_load(:action_view) do
        include Biscuit::BiscuitHelper
      end
    end

    # Register i18n locale files
    initializer "biscuit.i18n" do
      config.i18n.load_path += Dir[Engine.root.join("config/locales/*.yml")]
    end
  end
end
```

### `config/routes.rb`

```ruby
Biscuit::Engine.routes.draw do
  post   "/consent", to: "consent#update"
  delete "/consent", to: "consent#destroy"
end
```

Mount in the host app's `config/routes.rb`:

```ruby
mount Biscuit::Engine, at: "/biscuit"
```

### `app/controllers/biscuit/consent_controller.rb`

```ruby
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
```

---

## View Helper

### `app/helpers/biscuit/biscuit_helper.rb`

```ruby
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
```

Usage in `app/views/layouts/application.html.erb`:

```erb
<%= biscuit_banner %>
```

Usage in views:

```erb
<% if biscuit_allowed?(:analytics) %>
  <%# load analytics script %>
<% end %>
```

---

## Banner Partial

### `app/views/biscuit/banner/_banner.html.erb`

Requirements:

- Outer wrapper `<div>` with:
  - `class="biscuit-banner"`
  - `data-controller="biscuit"`
  - `data-biscuit-position-value="<%= Biscuit.configuration.position %>"`
  - `data-biscuit-csrf-token-value="<%= form_authenticity_token %>"`
  - `data-biscuit-endpoint-value="<%= biscuit.consent_path %>"`
  - `data-biscuit-already-consented-value="<%= consent.given? %>"`
  - `role="dialog"` and `aria-label` from i18n key `biscuit.banner.aria_label`
- Banner contains:
  - Message paragraph (i18n: `biscuit.banner.message`)
  - "Learn more" link to `Biscuit.configuration.privacy_policy_url` (i18n: `biscuit.banner.learn_more`)
  - "Accept all" button (`data-action="click->biscuit#acceptAll"`, class `biscuit-btn biscuit-btn--primary`)
  - "Reject non-essential" button (`data-action="click->biscuit#rejectAll"`, class `biscuit-btn biscuit-btn--secondary`)
  - "Manage preferences" button (`data-action="click->biscuit#togglePreferences"`, class `biscuit-btn biscuit-btn--secondary`)
  - Preferences panel (`data-biscuit-target="preferencesPanel"`, class `biscuit-preferences`, `hidden` attribute by default):
    - One row per configured category (iterate `Biscuit.configuration.categories`)
    - Necessary: checkbox `disabled` + `checked`, labelled as required
    - Non-required categories: checkbox with `data-biscuit-target="categoryCheckbox"` and `data-category="<key>"`
    - Pre-check each checkbox based on `consent.allowed?(key)` if consent already given
    - Each label uses i18n keys `biscuit.categories.<key>.name` and `biscuit.categories.<key>.description`
    - "Save preferences" button (`data-action="click->biscuit#savePreferences"`)
- Outside/below the banner: a "Cookie settings" button (`data-biscuit-target="manageLink"`, class `biscuit-manage-link`, `hidden` attribute by default, `data-action="click->biscuit#reopen"`)
- All interactive elements have appropriate ARIA attributes
- The banner must not auto-dismiss — only an explicit user action closes it

---

## Stimulus Controller

### `app/assets/javascripts/biscuit/biscuit_controller.js`

Plain ES module — no build step required.

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preferencesPanel", "categoryCheckbox", "manageLink"]
  static values  = {
    endpoint:         String,
    csrfToken:        String,
    position:         { type: String, default: "bottom" },
    alreadyConsented: { type: Boolean, default: false }
  }

  connect() {
    if (this.alreadyConsentedValue) {
      this.#hideBanner()
      this.#showManageLink()
    }
  }

  acceptAll() {
    this.#post(this.#allCategories(true))
  }

  rejectAll() {
    this.#post(this.#allCategories(false))
  }

  togglePreferences() {
    const panel  = this.preferencesPanelTarget
    const isOpen = panel.classList.contains("biscuit-preferences--open")
    panel.classList.toggle("biscuit-preferences--open", !isOpen)
    panel.hidden = isOpen
  }

  savePreferences() {
    const categories = {}
    this.categoryCheckboxTargets.forEach(cb => {
      categories[cb.dataset.category] = cb.checked
    })
    this.#post(categories)
  }

  reopen() {
    this.#showBanner()
    this.#hideManageLink()
  }

  // Private

  #allCategories(value) {
    const categories = {}
    this.categoryCheckboxTargets.forEach(cb => {
      categories[cb.dataset.category] = value
    })
    return categories
  }

  async #post(categories) {
    try {
      const response = await fetch(this.endpointValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token":  this.csrfTokenValue
        },
        body: JSON.stringify({ categories })
      })
      if (response.ok) {
        this.#hideBanner()
        this.#showManageLink()
      }
    } catch (error) {
      console.error("[Biscuit] Failed to save consent:", error)
    }
  }

  #hideBanner()     { this.element.hidden = true;  this.element.setAttribute("aria-hidden", "true") }
  #showBanner()     { this.element.hidden = false; this.element.removeAttribute("aria-hidden") }
  #showManageLink() { if (this.hasManageLinkTarget) this.manageLinkTarget.hidden = false }
  #hideManageLink() { if (this.hasManageLinkTarget) this.manageLinkTarget.hidden = true }
}
```

**Host app setup** (`app/javascript/controllers/index.js`):

```javascript
import BiscuitController from "biscuit/biscuit_controller"
application.register("biscuit", BiscuitController)
```

**Import map pin** (`config/importmap.rb`):

```ruby
pin "biscuit/biscuit_controller", to: "biscuit/biscuit_controller.js"
```

---

## i18n

### `config/locales/en.yml`

```yaml
en:
  biscuit:
    banner:
      aria_label:  "Cookie consent"
      message:     "We use cookies to improve your experience on this site."
      learn_more:  "Learn more"
      accept_all:  "Accept all"
      reject_all:  "Reject non-essential"
      manage:      "Manage preferences"
      save:        "Save preferences"
      reopen:      "Cookie settings"
    categories:
      necessary:
        name:        "Necessary"
        description: "Required for the site to function. Cannot be disabled."
      analytics:
        name:        "Analytics"
        description: "Help us understand how visitors use the site."
      marketing:
        name:        "Marketing"
        description: "Used to show personalised advertisements."
      preferences:
        name:        "Preferences"
        description: "Remember your settings and personalisation choices."
```

### `config/locales/fr.yml`

Provide complete French translations for all keys above.

---

## CSS

### `app/assets/stylesheets/biscuit/biscuit.css`

All styles scoped under `.biscuit-banner`. CSS custom properties defined on `.biscuit-banner` — host app overrides any token in its own stylesheet without touching the gem.

```css
.biscuit-banner {
  /* Tokens — override in your app's CSS */
  --biscuit-bg:              #1a1a1a;
  --biscuit-color:           #f5f5f5;
  --biscuit-muted:           #a0a0a0;
  --biscuit-accent:          #4f46e5;
  --biscuit-accent-hover:    #4338ca;
  --biscuit-border:          rgba(255,255,255,0.1);
  --biscuit-radius:          0.375rem;
  --biscuit-font-size:       0.875rem;
  --biscuit-font-family:     inherit;
  --biscuit-z-index:         9999;
  --biscuit-padding:         1rem 1.5rem;
  --biscuit-shadow-bottom:   0 -2px 12px rgba(0,0,0,0.25);
  --biscuit-shadow-top:      0 2px 12px rgba(0,0,0,0.25);
  --biscuit-max-width:       64rem;

  position:    fixed;
  left:        0;
  right:       0;
  z-index:     var(--biscuit-z-index);
  background:  var(--biscuit-bg);
  color:       var(--biscuit-color);
  font-size:   var(--biscuit-font-size);
  font-family: var(--biscuit-font-family);
  padding:     var(--biscuit-padding);
}

.biscuit-banner[data-biscuit-position-value="bottom"] {
  bottom:     0;
  box-shadow: var(--biscuit-shadow-bottom);
}

.biscuit-banner[data-biscuit-position-value="top"] {
  top:        0;
  box-shadow: var(--biscuit-shadow-top);
}

.biscuit-banner__inner {
  max-width:   var(--biscuit-max-width);
  margin:      0 auto;
  display:     flex;
  flex-wrap:   wrap;
  align-items: center;
  gap:         0.75rem;
}

.biscuit-banner__message { flex: 1 1 20rem; }

.biscuit-banner__actions {
  display:   flex;
  flex-wrap: wrap;
  gap:       0.5rem;
}

.biscuit-btn {
  display:       inline-flex;
  align-items:   center;
  padding:       0.4rem 0.9rem;
  border-radius: var(--biscuit-radius);
  font-size:     var(--biscuit-font-size);
  font-weight:   500;
  cursor:        pointer;
  border:        1px solid transparent;
  transition:    background 0.15s, color 0.15s;
  white-space:   nowrap;
}

.biscuit-btn--primary {
  background: var(--biscuit-accent);
  color:      #fff;
}
.biscuit-btn--primary:hover  { background: var(--biscuit-accent-hover); }

.biscuit-btn--secondary {
  background:   transparent;
  color:        var(--biscuit-color);
  border-color: var(--biscuit-border);
}
.biscuit-btn--secondary:hover { background: rgba(255,255,255,0.08); }

.biscuit-preferences { width: 100%; margin-top: 0.75rem; border-top: 1px solid var(--biscuit-border); padding-top: 0.75rem; }
.biscuit-preferences:not(.biscuit-preferences--open) { display: none; }

.biscuit-preference-row {
  display:       flex;
  align-items:   flex-start;
  gap:           0.75rem;
  padding:       0.5rem 0;
  border-bottom: 1px solid var(--biscuit-border);
}
.biscuit-preference-row:last-child    { border-bottom: none; }
.biscuit-preference-row__label       { flex: 1; }
.biscuit-preference-row__name        { font-weight: 600; display: block; }
.biscuit-preference-row__description { color: var(--biscuit-muted); font-size: 0.8rem; }

.biscuit-manage-link {
  position:        fixed;
  z-index:         var(--biscuit-z-index);
  font-size:       0.75rem;
  color:           var(--biscuit-muted);
  background:      transparent;
  border:          none;
  cursor:          pointer;
  padding:         0.25rem 0.5rem;
  text-decoration: underline;
}
.biscuit-manage-link[data-biscuit-position-value="bottom"] { bottom: 0.5rem; left: 1rem; }
.biscuit-manage-link[data-biscuit-position-value="top"]    { top: 0.5rem;    left: 1rem; }

@media (max-width: 640px) {
  .biscuit-banner__inner   { flex-direction: column; align-items: flex-start; }
  .biscuit-banner__actions { width: 100%; }
  .biscuit-btn             { flex: 1 1 auto; justify-content: center; }
}
```

Host app includes the stylesheet in the layout:

```erb
<%= stylesheet_link_tag "biscuit/biscuit" %>
```

---

## Tests

### `test/biscuit/configuration_test.rb`
- Default `cookie_name` is `"biscuit_consent"`.
- Default categories include `:necessary` with `required: true`.
- Default `position` is `:bottom`.
- `configure` block overrides `cookie_expires_days`.
- Custom categories hash is stored correctly.
- `reset_configuration!` restores all defaults.

### `test/biscuit/consent_test.rb`
- `Consent.parse` returns nil for nil input.
- `Consent.parse` returns nil for an empty string.
- `Consent.parse` returns nil for invalid JSON.
- `Consent.parse` returns nil if version field is missing or wrong.
- `Consent.parse` returns the parsed hash for a valid cookie string.
- `Consent.build_value` always sets `"necessary"` to true.
- `Consent.build_value` sets `"v"` to `1`.
- `Consent.build_value` sets `"consented_at"` to a UTC ISO8601 string (stub `Time.now`).
- `Consent.build_value` correctly coerces string `"true"`/`"false"` to booleans.
- `#given?` returns false when cookie is absent.
- `#given?` returns true when a valid cookie is present.
- `#allowed?(:necessary)` returns true regardless of cookie state.
- `#allowed?(:analytics)` returns false when no cookie is present.
- `#allowed?(:analytics)` returns true when cookie has `analytics: true`.
- `#allowed?(:analytics)` returns false when cookie has `analytics: false`.

### `test/biscuit/helper_test.rb`
- `biscuit_allowed?` returns true for `:necessary` with no cookie.
- `biscuit_allowed?` returns false for `:analytics` with no cookie.
- `biscuit_allowed?` returns true for `:analytics` when consent cookie grants it.
- `biscuit_banner` renders the banner partial.

### `test/integration/banner_test.rb` (Capybara)
- Banner is visible on first visit (no cookie present).
- Clicking "Accept all" hides the banner.
- Clicking "Accept all" sets the consent cookie with all non-required categories as true.
- Clicking "Reject non-essential" sets all non-required categories as false.
- Clicking "Manage preferences" reveals the preferences panel.
- Toggling a checkbox and clicking "Save preferences" stores the correct per-category values.
- After consent is given and the page is reloaded, the banner is not shown.
- After consent is given, the "Cookie settings" link is visible.
- Clicking "Cookie settings" reopens the banner.
- `POST /biscuit/consent` with a valid payload and CSRF token returns `{ "ok": true }`.
- `POST /biscuit/consent` without a CSRF token returns 422.
- `DELETE /biscuit/consent` clears the consent cookie and returns `{ "ok": true }`.

---

## README

Write a complete `README.md` covering:

1. Requirements (Rails 8.0+, Ruby 3.2+, Stimulus, import maps)
2. Installation — add to `Gemfile`, `bundle install`
3. Mount the engine in `config/routes.rb`
4. Pin the Stimulus controller in `config/importmap.rb`
5. Register the Stimulus controller in `app/javascript/controllers/index.js`
6. Include the stylesheet in the layout with `stylesheet_link_tag`
7. Add `<%= biscuit_banner %>` to `application.html.erb`
8. Full configuration reference with all options and their defaults
9. Defining custom cookie categories and adding the corresponding i18n keys
10. CSS theming — list all `--biscuit-*` custom properties and show an override example
11. Checking consent in views with `biscuit_allowed?(:category)`
12. Checking consent in controllers via `Biscuit::Consent.new(cookies).allowed?(:category)`
13. GDPR notes — what this gem does and does not do; the host app is responsible for its privacy policy and for ensuring no non-essential scripts fire before consent is given

---

## GDPR Compliance Checklist

- [ ] No non-essential cookies are set before consent is given (the gem itself only writes the consent cookie, which is functional/necessary)
- [ ] Consent is freely given — "Accept all" and "Reject non-essential" are equally prominent; no pre-ticked boxes; no dark patterns
- [ ] User can withdraw or amend consent at any time via the "Cookie settings" link
- [ ] Consent is granular — recorded per category
- [ ] Consent is timestamped in the cookie payload
- [ ] Necessary cookies are clearly labelled and non-toggleable
- [ ] The banner does not auto-dismiss — only an explicit user action closes it

---

## Out of Scope for v1

- Database-backed consent storage
- Geo-targeting (show only to EU visitors)
- Auto-blocking of third-party `<script>` tags based on consent (document as a host-app pattern in README instead)
- Turbo Stream updates post-consent
- jsbundling / esbuild support
