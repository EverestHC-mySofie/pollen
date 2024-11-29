# frozen_string_literal: true

module Pollen
  module Commands
    def completed!(stream_or_id, payload)
      push!(stream_or_id, :completed, payload)
    end

    def failed!(stream_or_id, payload)
      push!(stream_or_id, :failed, payload)
    end

    def push!(stream_or_id, event, payload)
      check_redis!
      stream = load_stream(stream_or_id)
      stream.update!(status: %i[completed failed].include?(event) && event || :pending, payload:)
      redis.publish("#{configuration.channel_prefix}:#{stream.id}", "#{event}:#{payload}")
    end

    private

    def redis
      configuration.redis
    end

    def check_redis!
      raise InvalidConfiguration, 'Redis not set, please assign a Redis client in client configuration' if redis.nil?
    end

    def load_stream(stream_or_id)
      stream_or_id.respond_to?(:id) && stream_or_id || Stream.find(stream_or_id).tap do |stream|
        raise Errors::InvalidStreamStatus, "Stream with id #{stream.id} is already #{stream.status}" unless stream.pending?
      end
    end
  end
end
