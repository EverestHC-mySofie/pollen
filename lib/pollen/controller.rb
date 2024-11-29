# frozen_string_literal: true

module Pollen
  class Controller
    include Configurable
    include Commands

    def configuration
      return @configuration if @configuration

      @configuration = CompositeConfiguration.new(
        ControllerConfiguration.new,
        Pollen.common.configuration
      )
    end
  end
end
