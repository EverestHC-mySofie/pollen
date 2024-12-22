# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pollen::Server do
  let(:streams) do
    stream = Struct.new(:id, :status, :payload, :timeout)
    [
      stream.new('bc343a24-fa98-4e29-9e6b-34b7c963ab63', 'pending', nil, 180),
      stream.new('0bd66195-c61b-40d8-aa40-b5fc0c4080c2', 'pending', nil, 180)
    ]
  end

  describe 'with concurrency set to 2' do
    let(:server) do
      described_class.new
    end
    let(:executor_doubles) { [double, double] }
    let(:sockets) { [double, double] }

    before do
      server.configure { |c| c.concurrency 2 }
    end

    before do
      2.times { |i| expect(Pollen::Executor).to receive(:new).and_return(executor_doubles[i]) }
      executor_doubles.each { |executor| expect(executor).to receive(:start!).and_return(executor) }
      expect_any_instance_of(Pollen::Subscriber).to receive(:start!)
    end

    it 'spawns two executors and a subscriber on startup' do
      expect(server.started?).to be false
      server.start!
      expect(server.started?).to be true
    end

    it 'routes incoming connection to the first executor based on partitioner' do
      server.start!
      expect(executor_doubles.first).to receive(:accept).with(Pollen::IncomingConnection)
      server.accept(sockets.first, streams.first)
    end

    it 'routes incoming connection to the second executor based on partitioner' do
      server.start!
      expect(executor_doubles.last).to receive(:accept).with(Pollen::IncomingConnection)
      server.accept(sockets.last, streams.last)
    end

    it 'pushes an event to the first executor based on partitioner' do
      server.start!
      expect(executor_doubles.first).to receive(:push).with(streams.first.id, 'ARGS')
      server.push(streams.first.id, 'ARGS')
    end

    it 'pushes an event connection to the second executor based on partitioner' do
      server.start!
      expect(executor_doubles.last).to receive(:push).with(streams.last.id, 'ARGS')
      server.push(streams.last.id, 'ARGS')
    end
  end

  describe Pollen::Executor do
    let(:executor) { described_class.new }
    let(:connection) { Pollen::IncomingConnection.new(streams.first.id, nil, nil, nil, nil) }
    let(:events) do
      {}.tap do |events|
        events[streams.first.id] = { event: 'message', data: 'data' }
      end
    end

    it 'spawns a new thread when starting' do
      expect(Thread).to receive(:new).and_yield
      expect(executor).to receive(:start_loop)
      expect(executor.start!).to eq executor
    end

    it 'fires the next tick in loop' do
      expect(executor).to receive(:loop).and_yield
      expect(executor).to receive(:next_tick)
      executor.send(:start_loop)
    end

    it 'proceeds the event loop and flushes incoming connections and events' do
      expect(Rails.logger).to receive(:info).with(/^Pushing data for stream/)
      expect(Rails.logger).to receive(:info).with(/^Creating connection for stream/)
      expect_any_instance_of(Pollen::EventLoop).to receive(:proceed).with(
        [connection], events
      )
      executor.push(streams.first.id, 'message', 'data')
      executor.accept(connection)
      executor.send :next_tick
    end
  end
end
