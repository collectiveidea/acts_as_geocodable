$:.unshift(File.dirname(__FILE__) + '/../lib')
plugin_test_dir = File.dirname(__FILE__)

require 'rubygems'
require 'bundler/setup'

require 'rspec'
require 'logger'

require 'active_support'
require 'active_record'
require 'action_controller'
require 'factory_girl'
require 'database_cleaner'
require 'ruby-debug'

require plugin_test_dir + '/../rails/init.rb'

ActiveRecord::Base.logger = Logger.new(plugin_test_dir + "/debug.log")

ActiveRecord::Base.configurations = YAML::load(IO.read(plugin_test_dir + "/db/database.yml"))
ActiveRecord::Base.establish_connection(ENV["DB"] || "mysql")
ActiveRecord::Migration.verbose = false
load(File.join(plugin_test_dir, "db", "schema.rb"))

require 'support/geocoder'

def assert_geocode_result(result)
  assert_not_nil result
  assert result.latitude.is_a?(BigDecimal) || result.latitude.is_a?(Float), "latitude is a #{result.latitude.class.name}"
  assert result.longitude.is_a?(BigDecimal) || result.longitude.is_a?(Float)
  
  # Depending on the geocoder, we'll get slightly different results
  assert_in_delta 42.787567, result.latitude, 0.001
  assert_in_delta -86.109039, result.longitude, 0.001
end

Rspec.configure do |config|
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

class Vacation < ActiveRecord::Base
  acts_as_geocodable :normalize_address => true
  belongs_to :nearest_city, :class_name => 'City', :foreign_key => 'city_id'
end

class City < ActiveRecord::Base
  acts_as_geocodable :address => {:postal_code => :zip}  
end

class ValidatedVacation < ActiveRecord::Base
  acts_as_geocodable
  validates_as_geocodable
end

class AddressBlobVacation < ActiveRecord::Base
  acts_as_geocodable :address => :address, :normalize_address => true
end

class CallbackLocation < ActiveRecord::Base
  acts_as_geocodable :address => :address
  set_callback :geocoding, :after, :done_geocoding
  # after_geocoding :done_geocoding
  
  def done_geocoding
    true
  end
end

require 'support/factories'