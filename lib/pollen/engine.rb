# frozen_string_literal: true

module Pollen
  if defined?(::Rails)
    class Engine < ::Rails::Engine
      isolate_namespace Pollen

      initializer 'pollen.add_middleware' do |app|
        app.middleware.insert_after ActionDispatch::Executor, Pollen::Middleware
      end
    end
  end
end
