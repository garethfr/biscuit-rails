require_relative "lib/biscuit/version"

Gem::Specification.new do |spec|
  spec.name        = "biscuit-rails"
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
