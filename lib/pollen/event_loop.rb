# frozen_string_literal: true

module Pollen
  class EventLoop
    def initialize
      @fibers = {}
    end

    def proceed(incoming, queue)
      incoming.each { |connection| start_fiber!(connection) }
      collector = {}
      @fibers.each do |stream_id, stream_fibers|
        resume_stream_fibers(stream_id, stream_fibers, queue[stream_id], collector)
      end
      prune collector
    end

    private

    def resume_stream_fibers(stream_id, fibers, event, collector)
      fibers.each do |fiber|
        fiber.resume event
      rescue FiberError
        # The fiber is dead
        collector[stream_id] ||= []
        collector[stream_id] << fiber
        Rails.logger.info "Closed connection for stream #{stream_id}"
      end
    end

    def prune(collector)
      collector.each do |stream_id, stream_fibers|
        stream_fibers.each do |fiber|
          @fibers[stream_id].delete(fiber)
        end
        @fibers.delete(stream_id) if @fibers[stream_id].empty?
      end
    end

    def start_fiber!(connection)
      fiber = Fiber.new { |conn| FiberBody.new.execute!(conn) }
      @fibers[connection.stream_id] ||= []
      @fibers[connection.stream_id] << fiber.tap { |f| f.resume(connection) }
    end
  end
end
