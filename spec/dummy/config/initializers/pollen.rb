# frozen_string_literal: true

Pollen.common.configure do |c|
  c.redis Redis.new(url: 'redis://localhost')
end

Pollen.server.configure do |c|
  c.authenticate do |_request, _env|
    User.first
  end

  # c.load_stream do |owner, id, _request, _env|
  #   Pollen::Stream.find_by(owner: owner, id: id)
  # end
end

Pollen.server.start! if ENV['START_POLLEN'] == 'true'
