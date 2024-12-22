# frozen_string_literal: true

require 'spec_helper'

class MutableIncomingConnection < Pollen::IncomingConnection
  attr_accessor :terminate_at, :event
end

RSpec.describe Pollen::FiberBody do
  let(:connection) do
    MutableIncomingConnection.new(
      nil, double, 'pending', JSON.dump({ this: { is: 'the payload' } }), (Time.now + 60.minutes).to_i
    )
  end
  let(:pusher) { double }
  let(:body) do
    described_class.new.tap { |body| body.instance_variable_set(:@pusher, pusher) }
  end
  let(:fiber) do
    Fiber.new { |conn| body.execute!(conn) }
  end

  describe 'handling a brand new connection' do
    before do
      expect(pusher).to receive(:write_headers)
      expect(pusher).to receive(:push).with(connection.payload, event: connection.event)
    end

    it 'initializes' do
      fiber.resume connection
    end

    it 'terminates' do
      connection.terminate_at = (Time.now - 1.second).to_i
      expect(pusher).to receive(:push).with(nil, event: 'terminated')
      expect(pusher).to receive(:close)
      fiber.resume connection
    end

    it 'pushes an heartbeat' do
      body.instance_variable_set(:@latest_heartbeat, (Time.zone.now - 6.seconds).to_i)
      expect(pusher).to receive(:comment)
      fiber.resume connection
    end

    it 'loops forever without pushing anything' do
      fiber.resume connection
      100.times { fiber.resume }
    end

    it 'pushes an event' do
      data = JSON.dump({})
      expect(pusher).to receive(:push).with(data, event: 'message')
      fiber.resume connection
      fiber.resume({ event: 'message', data: })
    end

    it 'completes' do
      data = JSON.dump({})
      expect(pusher).to receive(:push).with(data, event: 'completed')
      expect(pusher).to receive(:push).with(nil, event: 'terminated')
      expect(pusher).to receive(:close)
      fiber.resume connection
      fiber.resume({ event: 'completed', data: })
    end

    it 'marks the stream as failed' do
      data = JSON.dump({})
      expect(pusher).to receive(:push).with(data, event: 'failed')
      expect(pusher).to receive(:push).with(nil, event: 'terminated')
      expect(pusher).to receive(:close)
      fiber.resume connection
      fiber.resume({ event: 'failed', data: })
    end
  end
end
