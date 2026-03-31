---
name: biscuit-install
description: Install and configure the biscuit-rails GDPR cookie consent gem. Checks compatibility, installs the gem, configures categories and position, audits existing cookies and tracking scripts, adds integration tests, and optionally commits.
disable-model-invocation: true
---

# biscuit-install

Complete installation and setup of biscuit-rails in this Rails app. Work through each step in order, confirming with the user before making any changes.

---

## Step 1 — Compatibility check

Read `Gemfile`, `Gemfile.lock`, and `.ruby-version` (if present) to check:

- **Ruby >= 3.2** — stop with a clear error if not met
- **Rails >= 8.0** — check `Gemfile.lock` for the rails version; stop if not met
- **Asset pipeline** — check Gemfile for `propshaft`. If absent, warn that `stylesheet_link_tag "biscuit/biscuit"` may need adjustment
- **JS setup** — check for `importmap-rails` vs `jsbundling-rails`/`vite_rails`. Note the difference for Step 5
- **Stimulus** — check for `stimulus-rails` or `hotwire-rails`. Warn if absent — Stimulus must be installed for the banner to work
- **Conflicts** — check for other cookie consent gems (`eu_cookie_law`, `cookieconsent`, `cookie_law`). Warn if found

Report findings before proceeding.

---

## Step 2 — Add gem to Gemfile

Check if `biscuit-rails` already appears in the Gemfile. If not:

- Add `gem "biscuit-rails"` to the Gemfile
- Run `bundle install`

If already present, skip this step.

---

## Step 3 — Mount the engine

Check `config/routes.rb` for an existing `mount Biscuit::Engine` line. If absent, add it inside the `routes.draw` block:

```ruby
mount Biscuit::Engine, at: "/biscuit"
```

---

## Step 4 — Configure the initializer

Ask the user the following questions before writing anything:

1. **Banner position** — top or bottom? (default: `bottom`)
2. **Cookie categories** — which categories beyond `necessary` are needed? Options: `analytics`, `marketing`, `preferences`, or custom names. (default: `analytics` and `marketing`)
3. **Reload on consent** — should the page reload after the user saves consent, so conditionally-loaded scripts activate immediately? (default: `false`)
4. **Privacy policy URL** — where does your privacy policy live? (default: `"/privacy"`)
5. **Cookie lifetime** — how many days should consent last? (default: `365`)

Then create `config/initializers/biscuit.rb` based on their answers. Example output:

```ruby
Biscuit.configure do |config|
  config.position            = :bottom
  config.privacy_policy_url  = "/privacy"
  config.cookie_expires_days = 365

  config.categories = {
    necessary:  { required: true },
    analytics:  { required: false },
    marketing:  { required: false }
  }
end
```

If `config/initializers/biscuit.rb` already exists, show the current content and ask before overwriting.

If custom category names are used, remind the user to add matching i18n keys to their locale files — for example:

```yaml
en:
  biscuit:
    categories:
      my_category:
        name: "My Category"
        description: "Used for..."
```

---

## Step 5 — Register the Stimulus controller

### If using importmap

Check `app/javascript/controllers/index.js`. If `biscuit/biscuit_controller` is not already imported, add:

```javascript
import BiscuitController from "biscuit/biscuit_controller"
application.register("biscuit", BiscuitController)
```

Ensure `application` is already imported at the top of that file (it will be in the standard Rails 8 scaffold).

### If using esbuild / jsbundling

The same import and register lines apply, but inform the user that `@hotwired/stimulus` must be marked as external in their esbuild config so it is not bundled twice:

```js
// esbuild.config.js
external: ["@hotwired/stimulus"]
```

---

## Step 6 — Add stylesheet and banner to layout

Check `app/views/layouts/application.html.erb`:

- Add `<%= stylesheet_link_tag "biscuit/biscuit" %>` inside `<head>` if not already present
- Add `<%= biscuit_banner %>` as the first child of `<body>` if not already present

If the layout file doesn't exist at that path, ask the user which layout file to modify.

If the app uses `reload_on_consent: true` (from Step 4), use:

```erb
<%= biscuit_banner(reload_on_consent: true) %>
```

---

## Step 7 — Cookie and tracking script audit

Scan the codebase for existing cookie and tracking usage that should be gated behind consent. Report all findings before making any changes — let the user decide what to wrap.

### Server-side cookies (Ruby)

Search `app/` for:
- `cookies[`, `cookies.permanent[`, `cookies.signed[`, `cookies.encrypted[`

For each result, determine whether it is a functional/necessary cookie (session, CSRF, etc.) or a tracking cookie. Non-necessary cookies should be wrapped in the relevant controller:

```ruby
if Biscuit::Consent.new(cookies).allowed?(:analytics)
  cookies[:my_tracking_cookie] = { value: "...", expires: 1.year }
end
```

### Client-side storage (JavaScript)

Search `app/assets/` and `app/javascript/` for:
- `document.cookie`
- `localStorage.setItem`
- `sessionStorage.setItem`

Non-necessary writes should check the `biscuit_consent` cookie before setting.

### Third-party scripts (layout/views)

Search `app/views/layouts/` and `app/views/` for known analytics and marketing patterns:

| Pattern | Category |
|---|---|
| `gtag(`, `googletagmanager.com`, `_gaq`, `ga(` | analytics |
| `GTM-` | analytics |
| `fbq(`, `connect.facebook.net` | marketing |
| `intercomSettings`, `widget.intercom.io` | marketing |
| `hj(`, `static.hotjar.com` | analytics |
| `hs-script-loader` | marketing |
| `_linkedin_data_partner_id` | marketing |

For each match, show the file, line number, and suggested wrapping:

```erb
<% if biscuit_allowed?(:analytics) %>
  <!-- existing script -->
<% end %>
```

Ask the user to confirm each wrapping before applying it.

---

## Step 8 — Add integration tests

Check whether the app uses Minitest (`test/`) or RSpec (`spec/`).

### Minitest

If `test/integration/biscuit_consent_test.rb` does not exist, create it:

```ruby
require "test_helper"

class BiscuitConsentTest < ActionDispatch::IntegrationTest
  test "banner is shown on first visit" do
    get "/"
    assert_response :success
    assert_select "[data-controller='biscuit']"
  end

  test "biscuit_allowed? returns false before consent" do
    get "/"
    assert_equal false, Biscuit::Consent.new(cookies).allowed?(:analytics)
  end

  test "biscuit_allowed? for necessary always returns true" do
    get "/"
    assert_equal true, Biscuit::Consent.new(cookies).allowed?(:necessary)
  end

  test "accept all sets consent cookie" do
    post "/biscuit/consent", params: {},
      headers: { "Content-Type" => "application/json" },
      as: :json,
      body: { categories: { analytics: true, marketing: true } }.to_json
    assert_response :success
    assert Biscuit::Consent.new(cookies).given?
    assert Biscuit::Consent.new(cookies).allowed?(:analytics)
  end

  test "reject all sets non-required categories to false" do
    post "/biscuit/consent", params: {},
      headers: { "Content-Type" => "application/json" },
      as: :json,
      body: { categories: { analytics: false, marketing: false } }.to_json
    assert_response :success
    assert Biscuit::Consent.new(cookies).given?
    assert_equal false, Biscuit::Consent.new(cookies).allowed?(:analytics)
  end
end
```

Adjust category names to match the categories configured in Step 4.

### RSpec

If `spec/requests/biscuit_consent_spec.rb` does not exist, create an equivalent using RSpec/Rails request spec syntax.

Run the new tests and confirm they pass before continuing.

---

## Step 9 — Optional commit

Ask the user: "Would you like to commit these changes?"

If yes, stage only the files that were created or modified during this setup and commit:

```
git add config/routes.rb config/initializers/biscuit.rb \
        app/views/layouts/application.html.erb \
        app/javascript/controllers/index.js \
        test/integration/biscuit_consent_test.rb
git commit -m "Install biscuit-rails cookie consent"
```

Do not use `git add -A` — only stage biscuit-related files.

---

## Summary

After all steps complete, print a summary of:
- What was installed and configured
- Which tracking scripts were wrapped (if any)
- Any manual steps remaining (custom i18n keys, esbuild config, layouts other than `application.html.erb`)
