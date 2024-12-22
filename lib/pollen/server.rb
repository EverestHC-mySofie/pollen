# frozen_string_literal: true

module Pollen
  class Executor
    def initialize
      @events = {}
      @incoming = []
      @mutex = Mutex.new
      @event_loop = EventLoop.new
    end

    def start!
      @thread = Thread.new do
        start_loop
      end
      self
    end

    def push(stream_id, event, data)
      Rails.logger.info "Pushing data for stream #{stream_id}, event: #{event}"
      @mutex.synchronize do
        @events[stream_id] = { event:, data: }
      end
    end

    def accept(connection)
      Rails.logger.info "Creating connection for stream #{connection.stream_id}"
      @mutex.synchronize do
        @incoming << connection
      end
    end

    private

    def start_loop
      loop do
        next_tick
      end
    end

    def next_tick
      incoming = nil
      events = nil
      @mutex.synchronize do
        incoming = @incoming
        events = @events
        @events = {}
        @incoming = []
      end
      proceed(incoming, events)
    end

    def proceed(incoming, events)
      @event_loop.proceed(incoming, events).tap { sleep 0.01 }
    end
  end

  class Server
    include Configurable

    def initialize
      @partitioner = Partitioner.new(configuration)
    end

    def start!
      @executors = Array.new(configuration.concurrency).map do
        Executor.new.start!
      end
      Subscriber.new(self).start!
      @started = true
      self
    end

    def started?
      !!@started
    end

    def push(stream_id, *args)
      executor(stream_id).push(stream_id, *args)
    end

    def accept(socket, stream)
      executor(stream.id).accept(
        IncomingConnection.new(stream.id, socket, stream.status, stream.payload, Time.now.to_i + stream.timeout)
      )
    end

    def configuration
      return @configuration if @configuration

      @configuration = CompositeConfiguration.new(
        ServerConfiguration.new,
        Pollen.common.configuration
      )
    end

    private

    def executor(stream_id)
      @executors[@partitioner.partition(stream_id)]
    end
  end
end
