# frozen_string_literal: true

Pollen.common.configure do |c|
  c.redis Redis.new(url: "redis://127.0.0.1:6379")
end

Pollen.server.configure do |c|
  c.authenticate do |request, env|
    User.first
  end
end

Pollen.server.start! if ENV['START_POLLEN'] == 'true'
