# frozen_string_literal: true

module Pollen
  class FiberBody
    def initialize
      @latest_heartbeat = Time.now.to_i
    end

    # TODO: Assign a Fiber scheduler to handle blocking kernel calls
    def execute!(connection)
      init!(connection)
      pusher.push(connection.payload, event: connection.event)
      loop! if pending?(connection.event)
      pusher.push(nil, event: :terminated)
      pusher.close
    rescue IOError
      # The Fiber should die when it can't write to socket
    end

    def init!(connection)
      @connection = connection
      pusher.write_headers
    end

    def loop!
      while Time.now.to_i < @connection.terminate_at
        heartbeat!
        event = Fiber.yield
        next unless event

        pusher.push(event[:data], event: event[:event])
        @latest_heartbeat = Time.now.to_i
        break if completed?(event[:event])
      end
    end

    def completed?(event)
      %w[completed failed].include?(event)
    end

    def pending?(event)
      !completed?(event)
    end

    def heartbeat!
      return unless Time.now.to_i > @latest_heartbeat + Pollen.server.configuration.heartbeat

      pusher.comment
      @latest_heartbeat = Time.now.to_i
    end

    def pusher
      @pusher ||= Pusher.new(@connection.socket)
    end
  end
end
