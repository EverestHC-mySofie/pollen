# Pollen

An HTTP pubsub engine allowing clients to wait for long running tasks and get data updates
from the server.

## How it works

Pollen allows client applications to subscribe to streams of server-sent events.

![Getting started](https://github.com/EverestHC-mySofie/pollen/blob/main/resources/pollen-getting-started.png?raw=true)

When a client application wants to subscribe to a steam, it opens an HTTP connection with the
Pollen server. Pollen hijacks Rack requests corresponding to a specific route set (`/pollens/streams/:stream_id`)
and opens long running HTTP connections handled by an event loop and Ruby Fibers. All requests
outside this route are ignored by Pollen and forwarded to Rails.

On the server-side, processes, such as background jobs, use the Pollen controller to push updates
and handle the streams states. Communication between the controllers and the server is performed
via Redis Pub/Sub.

Thanks to the event loop and the usage of Ruby Fibers, Pollen can handle 10k+ concurrent connections
on a single CPU.

![Event Loop](https://github.com/EverestHC-mySofie/pollen/blob/main/resources/pollen-event-loop.png?raw=true)

## Installation

Add this line to your application's Gemfile:

```ruby
gem "pollen"
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install pollen
```

To install the migrations into your Rails application:

```bash
rails pollen:install:migrations
```

## Usage

### Authenticate stream clients

We create a module that extracts access tokens from requests:

```ruby
# lib/token_extractor.rb

module TokenExtractor
  class << self
    def token(request)
      pattern = /^Bearer /
      header  = request.headers['Authorization']
      return unless header&.match(pattern)

      header.gsub(pattern, '')
    end
  end
end
```

### Start the pollen server

We then create an initializer to provide the Redis client and the authentication method to the
Pollen server.  We also start the Pollen server if the environment variable `START_POLLEN` is
set to `true`.

```ruby
# config/initializers/pollen.rb

# Configuration shared by servers and controllers
Pollen.common.configure do |c|
  c.redis Redis.new(url: "redis://127.0.0.1:6379")
end

Pollen.server.configure do |c|
  c.authenticate do |request, env|
    token = TokenExtractor.token(request)
    break if token.blank?

    AccessToken.find_by(token: token)&.user
  end
end

Pollen.server.start! if ENV['START_POLLEN'] == 'true'
```

### Push events using the controller

Now, when the client application calls Rails to perform long-running task, such as generating 
the quaterly report of the _World Company®_, a regular Rails controller authenticates the
user, creates a _Stream_ instance and enqueues a background job. It then renders the _Stream_.

```ruby
# app/controllers/admin/reports_controller.rb

module Admin
  class ReportsController < ActionController::API
    before_action :authenticate_user

    def create
      stream = Pollen::Stream.create!(owner: current_user, timeout: 600)
      GenerateQuarterlyReportJob.perform_later(stream)
      render json: stream
    end
  end
end
```

When the client application gets the response, it uses the _Stream_ identifier to open a
connection to the Pollen server. It provides its access token so that the Pollen server
can authenticate the connection. As soon as the client has connected to the _Stream_, it
will get the initial status of the _Stream_ and regular heartbeats (every 10 seconds, by
default):

```bash
$ curl -N -H "Authorization: Bearer d87bdfe991fd4b892fc49e145c7dc8e38477b2ec08eee2aeb07441658a7a8c57" \
  http://0.0.0.0:3000/pollen/streams/708100af-2eba-4db3-b0a2-1847abee202c
event: pending
event: heartbeat
event: heartbeat
```

The job performs the report generation and regularly notifies the client application using
the Pollen controller. Once the report is fully generated, the controller marks the stream
as completed and closes the connection:

```ruby
# app/jobs/generate_quaterly_report_job.rb

class GenerateQuarterlyReportJob < ApplicationJob
  def perform(stream)
    10.times do |i|
      Pollen.controller.push!(stream, :update, { step: i }.to_json)
      sleep 1
    end
    Report.create!
    Pollen.controller.completed!(stream, report.to_json)
  rescue
    Pollen.controller.failed!(stream, {})
  end
end
```

The client will see this stream of events before the server closes the connection:

```
event: heartbeat
event: update
data: {"step":0}
event: update
data: {"step":1}
event: heartbeat
event: update
data: {"step":2}
event: update
data: {"step":3}
event: update
data: {"step":4}
event: update
data: {"step":5}
event: update
data: {"step":6}
event: update
data: {"step":7}
event: heartbeat
event: update
data: {"step":8}
event: update
data: {"step":9}
event: completed
data: {"id":"702943d6-49e4-45ba-9a6f-630fadd3e2c7"}
event: terminated
```

### Delete old streams

Stream instances are stored in the database and, in high traffic environments,
may pile up to millions of records a day.

Pollen provides a `pollen:prune_streams` Rails task typically run from a scheduled
task such as a Cron job. As _Stream_ objects are basically _ActiveRecord_ models,
it is also possible to use plain-old ActiveRecord queries to delete oldest _Streams_.

### Configuration

See the [wiki](https://github.com/EverestHC-mySofie/pollen/wiki/Configuration) for configuration options.

## Contributing

Feel free to file an issue or create a pull request <3

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
