# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pollen::EventLoop do
  describe 'proceeding' do
    let(:incoming_connections) do
      Array.new(2) do
        Pollen::IncomingConnection.new(
          SecureRandom.uuid, nil, nil, nil, nil
        )
      end
    end

    let(:event_loop) { described_class.new }

    it 'starts a new fiber for each incoming connection' do
      fiber_doubles = [double, double]
      body_doubles = [double, double]
      2.times do |i|
        expect(Pollen::FiberBody).to receive(:new).and_return(body_doubles[i])
        expect(body_doubles[i]).to receive(:execute!).with(incoming_connections[i])
        expect(Fiber).to receive(:new).and_yield(incoming_connections[i]).and_return(fiber_doubles[i])
        expect(fiber_doubles[i]).to receive(:resume).with(incoming_connections[i])
        expect(fiber_doubles[i]).to receive(:resume)
      end
      event_loop.proceed(incoming_connections, {})
    end

    describe 'resuming existing fibers' do
      let(:stream_ids) { Array.new(2) { SecureRandom.uuid } }
      let(:fiber_doubles) { [double, double] }
      let(:event) { { event: 'message', data: '' } }
      let(:events) do
        {}.tap do |events|
          # Only define an event for the first fiber
          events[stream_ids.first] = event
        end
      end
      let(:fibers_tree) do
        {}.tap do |tree|
          tree[stream_ids.first] = [fiber_doubles.first]
          tree[stream_ids.last] = [fiber_doubles.last]
        end
      end

      it 'resumes with an event if any and resumes otherwise' do
        event_loop.instance_variable_set :@fibers, fibers_tree
        expect(fiber_doubles.first).to receive(:resume).with(event)
        expect(fiber_doubles.last).to receive(:resume).with(nil)
        event_loop.proceed([], events)
      end

      it 'prunes dead fibers' do
        event_loop.instance_variable_set :@fibers, fibers_tree
        expect(fiber_doubles.first).to receive(:resume).and_raise(FiberError)
        expect(fiber_doubles.last).to receive(:resume).with(nil)
        event_loop.proceed([], {})
        expect(event_loop.instance_variable_get(:@fibers).keys).to eq [stream_ids.last]
      end
    end
  end
end
