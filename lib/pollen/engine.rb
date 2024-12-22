# frozen_string_literal: true

module Pollen
  if defined?(::Rails)
    class Engine < ::Rails::Engine
      isolate_namespace Pollen

      initializer 'pollen.add_middleware' do |app|
        app.middleware.insert_after ActionDispatch::Executor, Pollen::Middleware
      end

      config.generators do |g|
        g.test_framework :rspec
        g.fixture_replacement :factory_bot
        g.factory_bot dir: 'spec/factories'
      end
    end
  end
end
