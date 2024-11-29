# frozen_string_literal: true

Pollen.common.configure do |c|
  cmd = "docker inspect --format '{{.NetworkSettings.Networks.mysofiepay_default.IPAddress}}'  " \
        'mysofiepay-redis-1 2>/dev/null'
  c.redis Redis.new(url: "redis://#{`#{cmd}`.chomp}")
end

Pollen.server.configure do |c|
  c.authenticate do |request, env|
    User.first
  end
end

Pollen.server.start! if ENV['START_POLLEN'] == 'true'
