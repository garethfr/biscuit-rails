require_relative "lib/biscuit/version"

Gem::Specification.new do |spec|
  spec.name        = "biscuit-rails"
  spec.version     = Biscuit::VERSION
  spec.authors     = ["Gareth James"]
  spec.homepage    = "https://github.com/garethfr/biscuit-rails"
  spec.summary     = "GDPR-compliant cookie consent banner for Rails 8"
  spec.description = "Biscuit provides a configurable GDPR cookie consent banner for Rails 8+ applications. " \
                     "It manages consent state via a browser cookie, exposes a Stimulus controller for " \
                     "interactivity, and supports i18n and CSS custom property theming with no build step required."
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 3.2"

  spec.metadata = {
    "homepage_uri"    => "https://bemused.org/projects/biscuit-rails",
    "source_code_uri" => spec.homepage,
    "changelog_uri"   => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "#{spec.homepage}/issues"
  }

  spec.add_dependency "rails", "~> 8.0"

  spec.files = Dir[
    "app/**/*",
    "config/**/*",
    "lib/**/*",
    "README.md",
    "CHANGELOG.md",
    "LICENSE"
  ]
end
