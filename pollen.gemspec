# frozen_string_literal: true

require_relative 'lib/pollen/version'

Gem::Specification.new do |spec|
  spec.name        = 'pollen'
  spec.version     = Pollen::VERSION
  spec.authors     = ['Jef Mathiot']
  spec.email       = ['jeff.mathiot@gmail.com']
  spec.homepage    = 'https://github.com/everestHC-mySofie/pollen'
  spec.summary     = 'An HTTP Pub/Sub engine for Rails.'
  spec.description = 'An HTTP Pub/Sub engine for Rails.'
  spec.license     = 'MIT'

  spec.required_ruby_version = '>= 3.1.0'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/everestHC-mySofie/pollen'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']
  end

  spec.add_dependency 'rails', '>= 7.2.0'
  spec.add_dependency 'redis'
end
