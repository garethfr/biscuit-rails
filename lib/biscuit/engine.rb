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
