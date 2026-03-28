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

    # Register JS pin with the host app's importmap (importmap-rails only)
    initializer "biscuit.importmap", before: "importmap" do |app|
      if app.config.respond_to?(:importmap)
        app.config.importmap.paths << Engine.root.join("config/importmap.rb")
        app.config.importmap.cache_sweepers << Engine.root.join("app/assets/javascripts")
      end
    end
  end
end
