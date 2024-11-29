# frozen_string_literal: true

module Pollen
  class Client
    include Configurable
    include Commands

    def configuration
      return @configuration if @configuration

      @configuration = CompositeConfiguration.new(
        ClientConfiguration.new,
        Pollen.common.configuration
      )
    end
  end
end
