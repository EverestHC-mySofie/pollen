# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Pollen::Middleware do
  let(:app) { double }
  let(:server) { Pollen.server }
  let(:middleware) { described_class.new(app) }

  it 'pass the request to the next middleware if server is not started' do
    expect(app).to receive(:call).with({})
    middleware.call({})
  end

  describe 'with the server started' do
    before { allow(server).to receive(:started?).and_return(true) }

    it 'pass the request to the next middleware if request path does not match a route to Pollen' do
      env = { 'PATH_INFO' => '/not_pollen' }
      expect(app).to receive(:call).with(env)
      middleware.call(env)
    end

    it 'raises if Rack hijacking not supported' do
      env = { 'PATH_INFO' => "/pollen/streams/#{SecureRandom.uuid}" }
      expect { middleware.call(env) }.to raise_error(StandardError, 'Unable to hijack HTTP connection')
    end

    describe 'and hijacking enabled' do
      let(:hijack) { double }
      let(:env) { { 'rack.hijack?' => true, 'rack.hijack' => hijack } }

      it 'returns a 401 if it was unable to authenticate' do
        env['PATH_INFO'] = "/pollen/streams/#{SecureRandom.uuid}"
        expect(middleware.call(env)).to eq [401, {}, []]
      end

      describe 'with an authenticated user' do
        let(:user) { create(:user) }

        before do
          Pollen.server.configure { |c| c.authenticate { |_, _| user } }
        end

        it 'returns a 404 if it was unable to find the stream' do
          create(:stream, owner: user)
          env['PATH_INFO'] = "/pollen/streams/#{SecureRandom.uuid}"
          expect(middleware.call(env)).to eq [404, {}, []]
        end

        it 'returns a 404 if it the stream does not belong to the owner' do
          stream = create(:stream, owner: create(:user))
          env['PATH_INFO'] = "/pollen/streams/#{stream.id}"
          expect(middleware.call(env)).to eq [404, {}, []]
        end

        it 'hijacks the connection' do
          stream = create(:stream, owner: user)
          socket = double
          env['PATH_INFO'] = "/pollen/streams/#{stream.id}"

          expect(hijack).to receive(:call).and_return socket
          expect(server).to receive(:accept).with socket, stream
          expect(middleware.call(env)).to eq [200, {}, []]
        end
      end
    end
  end
end
