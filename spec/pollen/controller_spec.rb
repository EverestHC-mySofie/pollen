# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Pollen::Controller do
  let(:controller) { described_class.new }
  let(:stream) { create(:stream) }
  let(:payload) { JSON.dump({ this: { is: 'the payload' } }) }
  let(:redis) { Redis.new }

  it 'return a composite configuration' do
    expect(controller.configuration).to be_instance_of(Pollen::CompositeConfiguration)
  end

  it 'yields the configuration' do
    controller.configure do |c|
      c.channel_prefix 'prefix:streams'
    end
    expect(controller.configuration.channel_prefix).to eq 'prefix:streams'
  end

  it 'raises on pushing if Redis is not set' do
    expect { controller.push!(stream, :message, payload) }.to raise_error(Pollen::Errors::InvalidConfiguration)
  end

  describe 'with a redis client' do
    before do
      controller.configure do |c|
        c.redis redis
      end
    end

    describe 'with a completed stream' do
      before do
        stream.completed!
      end

      it 'complains the stream as an invalid status' do
        expect { controller.push!(stream, :message, payload) }.to raise_error(Pollen::Errors::InvalidStreamStatus)
      end
    end

    describe 'with a failed stream' do
      before do
        stream.failed!
      end

      it 'complains the stream as an invalid status' do
        expect { controller.push!(stream, :message, payload) }.to raise_error(Pollen::Errors::InvalidStreamStatus)
      end
    end

    describe 'with a pending stream' do
      it 'updates the stream state and pushes the event to Redis' do
        expect(redis).to receive(:publish).with("pollen:streams:#{stream.id}", "message:#{payload}")
        controller.push!(stream, :message, payload)
      end

      it 'completes the stream and pushes the event to Redis' do
        expect(redis).to receive(:publish).with("pollen:streams:#{stream.id}", "completed:#{payload}")
        controller.completed!(stream, payload)
        expect(stream.completed?).to be true
      end

      it 'marks the stream as failed and pushes the event to Redis' do
        expect(redis).to receive(:publish).with("pollen:streams:#{stream.id}", "failed:#{payload}")
        controller.failed!(stream, payload)
        expect(stream.failed?).to be true
      end
    end
  end
end
