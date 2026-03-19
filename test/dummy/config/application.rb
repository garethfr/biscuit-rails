require_relative "boot"

require "action_controller/railtie"
require "action_view/railtie"

require "biscuit"

module Dummy
  class Application < Rails::Application
    config.load_defaults 8.0
    config.eager_load = false
    config.secret_key_base = "biscuit_test_secret_key_base_for_testing_only_do_not_use_in_production"
  end
end
