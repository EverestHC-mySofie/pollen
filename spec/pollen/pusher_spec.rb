# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pollen::Pusher do
  def strip_newline(content)
    content.gsub(/\n\z/, '')
  end

  let(:socket) { double }
  let(:pusher) { described_class.new(socket) }
  let(:headers) do
    strip_newline(
      <<~HEADERS
        HTTP/1.1 200
        Content-Type: text/event-stream
        Transfer-Encoding: chunked
        X-Accel-Buffering: no
        Cache-Control: no-cache
      HEADERS
    )
  end

  it 'writes headers' do
    expect(socket).to receive(:puts).with(headers)
    expect(socket).to receive(:puts)
    pusher.write_headers
  end

  it 'writes a comment' do
    expect(socket).to receive(:puts).with "3\r\n:\n\n\r\n"
    pusher.comment
  end

  it 'pushes an event' do
    expect(socket).to receive(:puts).with "19\r\nevent:message\ndata:DATA\n\n\r\n"
    pusher.push('DATA', event: 'message')
  end

  it 'raises an IOError when putting to socket failed' do
    expect(socket).to receive(:puts).and_raise StandardError
    expect { pusher.comment }.to raise_error(Pollen::IOError)
  end

  describe 'on closing the socket' do
    before do
      expect(socket).to receive(:puts).with "0\r\n\r\n"
    end

    it 'writes the last chunk and closes the socket' do
      expect(socket).to receive(:close)
      pusher.close
    end

    it 'raises an IOError when socket could not be closed' do
      expect(socket).to receive(:close).and_raise StandardError
      expect { pusher.close }.to raise_error(Pollen::IOError)
    end
  end
end
