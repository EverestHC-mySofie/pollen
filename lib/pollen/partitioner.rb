# frozen_string_literal: true

module Pollen
  class Partitioner
    attr_reader :concurrency

    def initialize(configuration)
      @configuration = configuration
    end

    def partition(uuid)
      Digest::MD5.new.tap { |d| d.update uuid }.hexdigest[...2].to_i(16) % @configuration.concurrency
    end
  end
end
