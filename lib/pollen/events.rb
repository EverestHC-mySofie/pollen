# frozen_string_literal: true

module Pollen
  module Events
    class Payload
      attr_reader :payload

      def initialize(payload)
        super()
        @payload = payload
      end
    end

    class Hearbeat
      def initialize(timestamp)
        super
        @timestamp = timestamp
      end
    end
  end
end
