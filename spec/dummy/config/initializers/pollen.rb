# frozen_string_literal: true

REDIS_URL_CMD = "docker inspect --format '{{.NetworkSettings.Networks.mysofiepay_default.IPAddress}}'  " \
                'mysofiepay-redis-1 2>/dev/null'

Pollen.logger = Rails.logger

Pollen.common.configure do |c|
  c.redis Redis.new(url: "redis://#{`#{REDIS_URL_CMD}`.chomp}")
end

Pollen.server.configure do |c|
  c.failed_subscriber_wait_time 5.seconds
  c.authenticate do |_request, _env|
    User.first
  end

  # c.load_stream do |owner, id, _request, _env|
  #   Pollen::Stream.find_by(owner: owner, id: id)
  # end
end

Pollen.server.start! if ENV['START_POLLEN'] == 'true'
