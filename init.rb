begin 
  require 'graticule'
rescue LoadError
  raise "Graticule >= 0.2.0 is required for acts_as_geocodable"
end
require File.dirname(__FILE__) + '/lib/acts_as_geocodable'
require File.dirname(__FILE__) + '/lib/geocoding'
require File.dirname(__FILE__) + '/lib/geocode'
require File.dirname(__FILE__) + '/lib/remote_location'
require File.dirname(__FILE__) + '/lib/compatibility'

ActiveRecord::Base.send :include, CollectiveIdea::Acts::Geocodable
ActionController::Base.send :include, CollectiveIdea::RemoteLocation