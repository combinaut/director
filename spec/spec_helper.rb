require 'bundler'
Bundler.require :default, :development

Combustion.initialize! :active_record, :action_controller

require 'rspec/rails'
require 'director'

# If you're using Capybara:
# require 'capybara/rails'

RSpec.configure do |config|
  config.use_transactional_fixtures = true
end

# Load all spec support files
Dir[File.expand_path("../support/**/*.rb", __FILE__)].each {|f| require f }
