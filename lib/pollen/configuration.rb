# frozen_string_literal: true

module Pollen
  class Configuration
    attr_reader :owner_class, :channel_prefix, :redis

    def initialize
      super
      @owner_class = nil
      @channel_prefix = nil
      @redis = nil
    end

    def assign_defaults
      @owner_class = 'User'
      @channel_prefix = 'pollen:streams'
    end

    def root
      self
    end
  end

  class ServerConfiguration < Configuration
    UUID_REGEXP = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/

    attr_reader :concurrency, :heartbeat, :route_regexp
    attr_accessor :authenticator, :stream_loader

    def initialize
      super
      @concurrency = 1
      @heartbeat = 5
      @route_regexp = %r{^/pollen/streams/(#{UUID_REGEXP})}
      @authenticator = ->(_, _) {}
      @stream_loader = ->(owner, id, _request, _env) { Stream.find_by(owner: owner, id: id) }
    end
  end

  class ControllerConfiguration < Configuration
    attr_reader :retention

    def initialize
      super
      @retention = 24.hours
    end
  end

  class CompositeConfiguration
    def initialize(*configs)
      @configs = configs
    end

    def method_missing(name, *_args, **_)
      @configs.each do |config|
        return config.send(name) if config.respond_to?(name) && !config.send(name).nil?
      end
      nil
    end

    def respond_to_missing?(name, _ = false)
      @configs.map { |config| config.respond_to?(name) }.any?
    end

    def root
      @configs.first
    end
  end

  class ConfigurationBuilder
    def initialize(configuration)
      @configuration = configuration
    end

    def authenticate(&block)
      @configuration.root.authenticator = block
    end

    def load_stream(&block)
      @configuration.root.stream_loader = block
    end

    def method_missing(name, *args, **_)
      @configuration.root.instance_variable_set("@#{name}", *args)
    end

    def respond_to_missing?(_name, _ = false)
      true
    end
  end

  module Configurable
    def configure
      yield ConfigurationBuilder.new(configuration)
    end
  end

  class Common
    include Configurable

    def configuration
      @configuration ||= Configuration.new.tap(&:assign_defaults)
    end
  end
end
