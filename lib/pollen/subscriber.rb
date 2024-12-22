# frozen_string_literal: true

require 'redis'

module Pollen
  class Subscriber
    def initialize(server)
      @server = server
    end

    def start!
      if redis.nil?
        raise Errors::InvalidConfiguration,
              'Redis not set, please assign a Redis client in server configuration'
      end

      Thread.new { subscribe! }
    end

    private

    def subscribe!
      redis.psubscribe("#{channel_prefix}:*") do |on|
        on.pmessage do |_, channel, message|
          event, data = message.split(':', 2)
          stream_id = stream_id_from_channel(channel)
          @server.push(stream_id, event, data) unless stream_id.blank? || event.blank?
        end
      end
    end

    def stream_id_from_channel(channel)
      /^#{channel_prefix}:(#{ServerConfiguration::UUID_REGEXP})/.match(channel)&.captures&.first
    end

    def channel_prefix
      @channel_prefix ||= Pollen.server.configuration.channel_prefix
    end

    def redis
      @redis ||= @server.configuration.redis
    end
  end
end
