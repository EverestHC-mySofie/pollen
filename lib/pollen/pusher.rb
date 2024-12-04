# frozen_string_literal: true

module Pollen
  class IOError < StandardError; end

  class Pusher
    def initialize(socket)
      @socket = socket
    end

    def write_headers
      socket_puts headers.join("\n")
      socket_puts
    end

    def comment
      write_chunk [':', "\n"].compact.join("\n")
    end

    def push(payload, event:)
      write_chunk ["event:#{event}", payload ? "data:#{payload}" : nil, "\n"].compact.join("\n")
    end

    def close
      write_last_chunk
      socket_close
    end

    private

    def write_chunk(data)
      socket_puts [data.bytesize.to_s(16), data, ''].join("\r\n")
    end

    def write_last_chunk
      socket_puts "0\r\n\r\n"
    end

    def headers
      [
        'HTTP/1.1 200',
        'Content-Type: text/event-stream',
        'Transfer-Encoding: chunked',
        'X-Accel-Buffering: no',
        'Cache-Control: no-cache'
      ]
    end

    def socket_puts(data = nil)
      @socket.puts data
    rescue StandardError
      raise IOError
    end

    def socket_close
      @socket.close
    rescue StandardError
      raise IOError
    end
  end
end
