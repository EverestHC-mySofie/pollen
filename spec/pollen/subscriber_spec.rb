# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pollen::Subscriber do
  let(:server) { Pollen::Server.new }
  let(:subscriber) { described_class.new(server) }

  it 'raises on startup if Redis is not configured' do
    expect { subscriber.start! }.to raise_error(Pollen::Errors::InvalidConfiguration)
  end

  describe 'with a Redis' do
    let(:redis) { Redis.new }
    before do
      server.configure { |c| c.redis redis }
      expect(Thread).to receive(:new).and_yield
    end

    it 'subscribes to the pattern' do
      expect(redis).to receive(:psubscribe).with('pollen:streams:*')
      subscriber.start!
    end

    describe 'subscribed to Redis' do
      let(:listener) { double }
      let(:uuid) { SecureRandom.uuid }

      before do
        expect(redis).to receive(:psubscribe).with('pollen:streams:*').and_yield listener
      end

      it 'pushes to server when receiving a message' do
        expect(listener).to receive(:pmessage).and_yield(nil, "pollen:streams:#{uuid}", 'message:data')
        expect(server).to receive(:push).with(uuid, 'message', 'data')
        subscriber.start!
      end

      it 'drops message if stream ID could not be extracted' do
        expect(listener).to receive(:pmessage).and_yield(nil, 'pollen:streams:XXX', 'message:data')
        expect(server).not_to receive(:push)
        subscriber.start!
      end

      it 'drops message if event could not be extracted' do
        expect(listener).to receive(:pmessage).and_yield(nil, "pollen:streams:#{uuid}", '')
        expect(server).not_to receive(:push)
        subscriber.start!
      end
    end
  end
end
