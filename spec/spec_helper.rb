# frozen_string_literal: true

require 'simplecov'
SimpleCov.add_filter 'spec'
SimpleCov.start

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.order = :random

  config.before(:each) do
    Pollen.common.instance_variable_set(:@configuration, nil)
    Pollen.controller.instance_variable_set(:@configuration, nil)
    Pollen.server.instance_variable_set(:@configuration, nil)
  end
end
