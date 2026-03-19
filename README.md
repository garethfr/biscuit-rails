# Biscuit

GDPR-compliant cookie consent banner for Rails 8. Renders a configurable
bottom/top banner, manages consent state via a browser cookie, and exposes a
Stimulus controller for interactivity. Supports i18n and CSS custom property
theming with no external runtime dependencies.

---

## Requirements

| Requirement | Version |
|---|---|
| Ruby | >= 3.2 |
| Rails | >= 8.0 |
| Stimulus | Any (via `@hotwired/stimulus`) |
| Import maps | Rails default (`importmap-rails`) |

No Sprockets, no build step. Assets are served via **Propshaft** (Rails 8
default).

---

## Installation

Add to your `Gemfile`:

```ruby
gem "biscuit-rails"
```

Then:

```sh
bundle install
```

---

## Setup

### 1. Mount the engine

In `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  mount Biscuit::Engine, at: "/biscuit"
  # ... your other routes
end
```

### 2. Pin the Stimulus controller

In `config/importmap.rb`:

```ruby
pin "biscuit/biscuit_controller", to: "biscuit/biscuit_controller.js"
```

### 3. Register the Stimulus controller

In `app/javascript/controllers/index.js`:

```javascript
import BiscuitController from "biscuit/biscuit_controller"
application.register("biscuit", BiscuitController)
```

### 4. Include the stylesheet

In your layout (`app/views/layouts/application.html.erb`):

```erb
<%= stylesheet_link_tag "biscuit/biscuit" %>
```

### 5. Render the banner

In your layout, inside `<body>`:

```erb
<%= biscuit_banner %>
```

That's it. The banner renders on every page. Once a user makes a consent
choice it hides itself and shows a small "Cookie settings" link so they can
revisit their preferences at any time.

---

## Banner Options

`biscuit_banner` accepts keyword options to control behaviour per-page:

### `reload_on_consent`

When `true`, the page reloads via `Turbo.visit` after the user saves their
consent choice, instead of just hiding the banner. This is useful when your
layout conditionally loads scripts based on consent — a reload ensures those
scripts are evaluated with the new cookie in place.

```erb
<%= biscuit_banner(reload_on_consent: true) %>
```

Default: `false` — the banner hides in place without a page reload.

---

## Configuration

Create an initializer at `config/initializers/biscuit.rb`:

```ruby
Biscuit.configure do |config|
  # Cookie categories — see "Custom categories" below
  config.categories = {
    necessary:   { required: true },
    analytics:   { required: false },
    preferences: { required: false },
    marketing:   { required: false }
  }

  # Name of the browser cookie that stores consent state
  # Default: "biscuit_consent"
  config.cookie_name = "biscuit_consent"

  # How long the consent cookie lasts, in days
  # Default: 365
  config.cookie_expires_days = 365

  # Cookie path
  # Default: "/"
  config.cookie_path = "/"

  # Cookie domain — nil means current domain
  # Default: nil
  config.cookie_domain = nil

  # SameSite attribute
  # Default: "Lax"
  config.cookie_same_site = "Lax"

  # Banner position: :bottom or :top
  # Default: :bottom
  config.position = :bottom

  # URL for the "Learn more" privacy policy link
  # Default: "#"
  config.privacy_policy_url = "/privacy"
end
```

### All options at a glance

| Option | Default | Description |
|---|---|---|
| `categories` | `{necessary: {required: true}, analytics: {required: false}, marketing: {required: false}}` | Cookie categories shown to the user |
| `cookie_name` | `"biscuit_consent"` | Browser cookie name |
| `cookie_expires_days` | `365` | Cookie lifetime in days |
| `cookie_path` | `"/"` | Cookie path |
| `cookie_domain` | `nil` | Cookie domain (nil = current domain) |
| `cookie_same_site` | `"Lax"` | SameSite cookie attribute |
| `position` | `:bottom` | Banner position (`:bottom` or `:top`) |
| `privacy_policy_url` | `"#"` | "Learn more" link URL |

---

## Custom Cookie Categories

Define any categories you need. Each entry requires a `:required` key.
Categories with `required: true` are shown as permanently checked and
non-toggleable (necessary cookies). All others are opt-in checkboxes.

```ruby
config.categories = {
  necessary:   { required: true },
  analytics:   { required: false },
  preferences: { required: false },
  marketing:   { required: false }
}
```

Add matching i18n keys for each custom category. For example, to add a
`preferences` category, add to `config/locales/en.yml`:

```yaml
en:
  biscuit:
    categories:
      preferences:
        name:        "Preferences"
        description: "Remember your settings and personalisation choices."
```

Biscuit ships with built-in translations for `necessary`, `analytics`,
`marketing`, and `preferences` in English and French. Any other category
requires you to add your own keys.

---

## CSS Theming

All styles are scoped under `.biscuit-banner`. Every visual property is
expressed as a CSS custom property, so you can override the entire look
without touching the gem.

### Available custom properties

| Property | Default | Description |
|---|---|---|
| `--biscuit-bg` | `Canvas` | Banner background colour (browser default background) |
| `--biscuit-color` | `CanvasText` | Banner text colour (browser default text) |
| `--biscuit-muted` | `GrayText` | Secondary / description text colour |
| `--biscuit-accent` | `#4f46e5` | Primary button background |
| `--biscuit-accent-hover` | `#4338ca` | Primary button hover background |
| `--biscuit-border` | `rgba(0,0,0,0.12)` | Divider / border colour |
| `--biscuit-radius` | `0.375rem` | Button / panel border radius |
| `--biscuit-font-size` | `0.875rem` | Base font size |
| `--biscuit-font-family` | `inherit` | Font family |
| `--biscuit-z-index` | `9999` | Stack order |
| `--biscuit-padding` | `1rem 1.5rem` | Banner padding |
| `--biscuit-shadow-bottom` | `0 -2px 12px rgba(0,0,0,0.12)` | Shadow when `position: bottom` |
| `--biscuit-shadow-top` | `0 2px 12px rgba(0,0,0,0.12)` | Shadow when `position: top` |
| `--biscuit-max-width` | `64rem` | Inner content max-width |

### Override example

In your application's CSS, after including the biscuit stylesheet:

```css
.biscuit-banner {
  --biscuit-accent:       #0070f3;
  --biscuit-accent-hover: #005bb5;
  --biscuit-border:       rgba(0, 0, 0, 0.08);
}
```

---

## Checking Consent in Views

Use the `biscuit_allowed?` helper, which is available in all views and
layouts:

```erb
<% if biscuit_allowed?(:analytics) %>
  <!-- Google Analytics or similar -->
  <script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXX"></script>
<% end %>

<% if biscuit_allowed?(:marketing) %>
  <!-- Marketing pixel -->
<% end %>
```

`:necessary` always returns `true` regardless of cookie state.

---

## Checking Consent in Controllers

```ruby
class ApplicationController < ActionController::Base
  def analytics_enabled?
    Biscuit::Consent.new(cookies).allowed?(:analytics)
  end
end
```

---

## Cookie Format

The consent cookie stores a JSON payload:

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

- `v` — schema version (currently `1`). Biscuit ignores cookies from
  unknown versions.
- `consented_at` — UTC ISO 8601 timestamp of when consent was recorded.
- `categories` — per-category boolean map. `necessary` is always `true`.

The cookie is **not** `httponly` so that client-side JavaScript can read
consent state for lazy-loading scripts.

---

## GDPR Notes

Biscuit provides the consent UI and storage mechanism. You are responsible for:

### What Biscuit does

- Renders a banner that requires an explicit user action before dismissal
  (no auto-dismiss)
- Offers equally prominent "Accept all" and "Reject non-essential" buttons
- Records granular, timestamped consent per category
- Allows the user to withdraw or amend consent at any time via the
  "Cookie settings" link
- Marks `:necessary` cookies as non-toggleable and clearly labelled
- Writes no non-essential cookies itself — only the consent cookie, which
  is a functional/necessary cookie

### What Biscuit does NOT do

- **It does not block third-party scripts automatically.** You must
  conditionally load scripts based on `biscuit_allowed?(:category)`.
  See the pattern below.
- It does not implement geo-targeting (showing the banner only to EU
  visitors).
- It does not store consent in a database (v1 is cookie-only).
- It does not provide a legal opinion on whether your implementation
  meets GDPR requirements. Consult a lawyer.

### Pattern: blocking non-essential scripts until consent

```erb
<%# In your layout — only load analytics after consent %>
<% if biscuit_allowed?(:analytics) %>
  <script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXX"></script>
  <script>
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());
    gtag('config', 'G-XXXXXX');
  </script>
<% end %>
```

For scripts that must load on the client side after a user accepts consent
during their current session (without a page reload), listen for the Fetch
response in your own JavaScript and initialise scripts there, or use a
lightweight Turbo visit to reload the page after the consent POST succeeds.
(Turbo Stream support for post-consent injection is planned for v2.)

### GDPR compliance checklist

- [x] No non-essential cookies set before consent
- [x] Consent is freely given — equal prominence for accept and reject
- [x] No pre-ticked boxes for non-required categories
- [x] No dark patterns
- [x] User can withdraw or amend consent at any time
- [x] Consent is granular — recorded per category
- [x] Consent is timestamped
- [x] Necessary cookies are clearly labelled and non-toggleable
- [x] Banner does not auto-dismiss

---

## i18n

Biscuit ships with English (`en`) and French (`fr`) translations. To add
another locale, create `config/locales/biscuit.<locale>.yml` in your app:

```yaml
de:
  biscuit:
    banner:
      aria_label:  "Cookie-Zustimmung"
      message:     "Wir verwenden Cookies, um Ihr Erlebnis auf dieser Website zu verbessern."
      learn_more:  "Mehr erfahren"
      accept_all:  "Alle akzeptieren"
      reject_all:  "Nicht wesentliche ablehnen"
      manage:      "Einstellungen verwalten"
      save:        "Einstellungen speichern"
      reopen:      "Cookie-Einstellungen"
    categories:
      necessary:
        name:        "Notwendig"
        description: "Für die Funktion der Website erforderlich. Kann nicht deaktiviert werden."
      analytics:
        name:        "Analyse"
        description: "Helfen uns zu verstehen, wie Besucher die Website nutzen."
      marketing:
        name:        "Marketing"
        description: "Werden verwendet, um personalisierte Werbung anzuzeigen."
      preferences:
        name:        "Präferenzen"
        description: "Speichern Ihre Einstellungen und Personalisierungsoptionen."
```

---

## Engine Routes

The engine mounts two endpoints:

| Method | Path | Action |
|---|---|---|
| `POST` | `/biscuit/consent` | Record consent for all categories |
| `DELETE` | `/biscuit/consent` | Clear the consent cookie |

Both endpoints require a valid CSRF token. The Stimulus controller
reads the token from the `data-biscuit-csrf-token-value` attribute
(set automatically by the banner partial from `form_authenticity_token`).

---

## License

MIT
