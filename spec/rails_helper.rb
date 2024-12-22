# frozen_string_literal: true

require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative 'dummy/config/environment'
# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rspec/rails'

require 'factory_bot_rails'

FactoryBot.definition_file_paths << File.join(File.dirname(__FILE__), 'factories')
FactoryBot.factories.clear
FactoryBot.find_definitions

begin
  ActiveRecord::Migrator.migrations_paths = File.join(File.dirname(__FILE__), 'dummy/db/migrate')
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end
RSpec.configure do |config|
  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods
end
