# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
