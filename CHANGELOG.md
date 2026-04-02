# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.1] - 2026-04-02

### Fixed

- `biscuit-install` skill: add Sprockets manifest step — when not using Propshaft,
  `biscuit/biscuit.css` and `biscuit/biscuit_controller.js` must be linked in
  `app/assets/config/manifest.js` or they 404 in test and production
- `biscuit-install` skill: fix integration test POST syntax — `body:` is not a valid
  Rails integration test keyword; replaced with `params: { ... }.to_json` and explicit
  `Content-Type`/`Accept` headers
- `biscuit-install` skill: explain why the Stimulus controller must be registered
  manually (`eagerLoadControllersFrom` only discovers controllers in
  `app/javascript/controllers/`, not gem-provided ones)

---

## [0.2.0] - 2026-03-31

### Added

- `rails generate biscuit:install` generator — installs a Claude Code skill
  into `.claude/skills/biscuit-install/` for AI-assisted setup
- `biscuit-install` Claude Code skill — guides developers through compatibility
  checks, engine mounting, Stimulus registration, initializer configuration,
  cookie and tracking script audit, integration tests, and optional commit
- README section documenting the AI-assisted setup workflow

---

## [0.1.4] - 2026-03-29

### Fixed

- Incorrect CSS float on banner element causing layout issues
- Incorrect banner height at small viewport widths

---

## [0.1.3] - 2026-03-28

### Fixed

- Manage link ("Cookie settings") button now works correctly — it was rendered
  outside the Stimulus controller's element scope, so targets and actions were
  never connected. The banner partial now wraps both the banner and the manage
  link in a single controller root element.

### Added

- Engine auto-registers its importmap pin with the host app via a
  `biscuit.importmap` initializer — users no longer need to manually add
  `pin "biscuit/biscuit_controller"` to `config/importmap.rb`. No-op in
  esbuild/jsbundling apps.

---

## [0.1.2] - 2026-03-20

### Added

- German (`de`) and Spanish (`es`) locale files

---

## [0.1.1] - 2026-03-19

### Added

- `reload_on_consent` option for `biscuit_banner` — when `true`, triggers a
  `Turbo.visit` page reload after consent is saved so conditionally-loaded
  scripts are evaluated with the updated cookie

---

## [0.1.0] - 2026-03-19

### Added

- GDPR-compliant cookie consent banner for Rails 8+
- Configurable banner position (top or bottom)
- Cookie categories with per-category consent tracking (necessary, analytics, marketing, preferences)
- Stimulus controller for accept all, reject all, manage preferences, and reopen flows
- Preferences panel with per-category checkboxes, pre-populated from existing consent state
- Persistent "Cookie settings" reopener link shown after consent is given
- Consent stored as a versioned JSON cookie (`biscuit_consent`)
- `biscuit_banner` view helper for rendering the banner in any layout
- `biscuit_allowed?(:category)` helper for conditional script/content loading in views
- `Biscuit::Consent.new(cookies).allowed?(:category)` for controller-level consent checks
- Full configuration API via `Biscuit.configure` initializer
- i18n support with English and French translations included
- CSS custom property theming — all visual tokens overridable without touching gem CSS
- Rails engine with isolated namespace, auto-mounted routes at `/biscuit/consent`
- No runtime dependencies beyond Rails itself
- No asset pipeline (Sprockets) dependency — assets served via Propshaft
- No JavaScript build step — delivered as a plain ES module for import maps
