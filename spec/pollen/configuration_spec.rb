# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pollen::Configuration do
  it 'defines default properties' do
    config = described_class.new.tap(&:assign_defaults)
    expect(config.channel_prefix).to eq 'pollen:streams'
    expect(config.owner_class).to eq 'User'
  end

  describe Pollen::ServerConfiguration do
    it 'defines default properties' do
      config = described_class.new
      expect(config.concurrency).to eq 1
      expect(config.heartbeat).to eq 5
      expect("/pollen/streams/#{SecureRandom.uuid}").to match config.route_regexp
    end
  end

  describe Pollen::ControllerConfiguration do
    it 'defines default properties' do
      config = described_class.new
      expect(config.retention).to eq 24.hours
    end
  end

  describe Pollen::CompositeConfiguration do
    let(:server_configuration) { Pollen::ServerConfiguration.new }
    let(:config) { described_class.new(server_configuration, Pollen::Configuration.new.tap(&:assign_defaults)) }

    it 'allows high-level configuration to override low-level properties' do
      expect(config.channel_prefix).to eq 'pollen:streams'
      server_configuration.instance_variable_set :@channel_prefix, 'another:prefix'
      expect(config.channel_prefix).to eq 'another:prefix'
    end
  end
end
