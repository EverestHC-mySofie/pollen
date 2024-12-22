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
      with_redis do |r|
        r.publish("#{configuration.channel_prefix}:#{stream.id}", "#{event}:#{payload}")
      end
    end

    private

    def redis
      configuration.redis
    end

    def with_redis(&block)
      # Allow raw Redis clients or a client from the pool
      configuration.redis.then(&block)
    end

    def check_redis!
      return unless redis.nil?

      raise Errors::InvalidConfiguration,
            'Redis not set, please assign a Redis client or connection pool in controller configuration'
    end

    def load_stream(stream_or_id)
      (stream_or_id.respond_to?(:id) && stream_or_id || Stream.find(stream_or_id)).tap do |stream|
        unless stream.pending?
          raise Errors::InvalidStreamStatus,
                "Stream with id #{stream.id} is already #{stream.status}"
        end
      end
    end
  end
end
