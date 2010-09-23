$:.unshift(File.dirname(__FILE__) + '/../lib')
plugin_test_dir = File.dirname(__FILE__)

require 'rubygems'
require 'bundler/setup'

require 'spec'
require 'logger'

require 'active_support'
require 'active_record'
require 'action_controller'
require 'factory_girl'

require plugin_test_dir + '/../rails/init.rb'

ActiveRecord::Base.logger = Logger.new(plugin_test_dir + "/debug.log")

ActiveRecord::Base.configurations = YAML::load(IO.read(plugin_test_dir + "/db/database.yml"))
ActiveRecord::Base.establish_connection(ENV["DB"] || "mysql")
ActiveRecord::Migration.verbose = false
load(File.join(plugin_test_dir, "db", "schema.rb"))

Geocode.geocoder ||= Graticule.service(:bogus).new

def assert_geocode_result(result)
  assert_not_nil result
  assert result.latitude.is_a?(BigDecimal) || result.latitude.is_a?(Float), "latitude is a #{result.latitude.class.name}"
  assert result.longitude.is_a?(BigDecimal) || result.longitude.is_a?(Float)
  
  # Depending on the geocoder, we'll get slightly different results
  assert_in_delta 42.787567, result.latitude, 0.001
  assert_in_delta -86.109039, result.longitude, 0.001
end
