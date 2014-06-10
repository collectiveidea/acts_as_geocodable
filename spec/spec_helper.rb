require "acts_as_geocodable"

require "bundler"
Bundler.require(:test)

plugin_test_dir = File.dirname(__FILE__)
ActiveRecord::Base.logger = Logger.new(plugin_test_dir + "/debug.log")
ActiveRecord::Base.configurations = YAML::load(IO.read(plugin_test_dir + "/db/database.yml"))
ActiveRecord::Base.establish_connection((ENV["DB"] || "mysql").to_sym)
ActiveRecord::Migration.verbose = false
load(File.join(plugin_test_dir, "db", "schema.rb"))

require "support/geocoder"
require "support/models"
require "support/factories"

RSpec.configure do |config|
  # Use database cleaner to remove factories
  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
  end
  config.before(:each) do
    DatabaseCleaner.start
  end
  config.after(:each) do
    DatabaseCleaner.clean
  end
end
