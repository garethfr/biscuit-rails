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
