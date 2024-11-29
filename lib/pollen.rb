# frozen_string_literal: true

require 'pollen/commands'
require 'pollen/configuration'
require 'pollen/event_loop'
require 'pollen/errors'
require 'pollen/events'
require 'pollen/fiber_body'
require 'pollen/partitioner'
require 'pollen/pusher'
require 'pollen/subscriber'

require 'pollen/controller'
require 'pollen/middleware'
require 'pollen/server'
require 'pollen/engine'

module Pollen
  class IncomingConnection
    attr_reader :stream_id, :socket, :event, :payload, :terminate_at

    def initialize(stream_id, socket, event, payload, terminate_at)
      @stream_id = stream_id
      @socket = socket
      @event = event
      @payload = payload
      @terminate_at = terminate_at
    end
  end

  class << self
    def server
      @server ||= Server.new
    end

    def controller
      @controller ||= Controller.new
    end

    def common
      @common ||= Common.new
    end
  end
end
