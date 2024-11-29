# frozen_string_literal: true

module Pollen
  module Errors
    class InvalidConfiguration < StandardError; end
    class InvalidStreamStatus < StandardError; end
    class AuthenticationFailure < StandardError; end
    class StreamNotFound < StandardError; end
  end
end
