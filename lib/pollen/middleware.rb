# frozen_string_literal: true

module Pollen
  class Middleware
    UUID_REGEXP = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/

    def initialize(app)
      @app = app
      @server = Pollen.server
      @route = @server.configuration.route_regexp
    end

    def call(env)
      request = Rack::Request.new(env)
      if @server.started? && (stream_id = request.path.match(@route)&.captures&.first)
        raise 'Unable to hijack HTTP connection' unless env['rack.hijack?']

        authenticate_and_hijack(request, env, stream_id)
      else
        @app.call(env)
      end
    end

    private

    def authenticate_and_hijack(request, env, stream_id)
      load_stream(stream_id, request, env).tap do |stream|
        @server.accept(env['rack.hijack'].call, stream)
      end
      [200, {}, []]
    rescue Errors::AuthenticationFailure
      [401, {}, []]
    rescue Errors::StreamNotFound
      [404, {}, []]
    end

    def authenticate_owner(stream_id, request, env)
      authenticator.call(request, env).tap do |owner|
        raise Errors::AuthenticationFailure, "Unable to authenticate user on stream #{stream_id}" if owner.nil?
      end
    end

    def load_stream(stream_id, request, env)
      stream_loader.call(authenticate_owner(stream_id, request, env), stream_id, request, env).tap do |stream|
        raise Errors::StreamNotFound, "Unable to find stream with ID #{stream_id}" if stream.nil?
      end
    end

    def authenticator
      @server.configuration.authenticator
    end

    def stream_loader
      @server.configuration.stream_loader
    end
  end
end
