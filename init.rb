require 'graticule'
require File.dirname(__FILE__) + '/lib/acts_as_geocodable'
require File.dirname(__FILE__) + '/lib/geocoding'
require File.dirname(__FILE__) + '/lib/geocode'
require File.dirname(__FILE__) + '/lib/remote_location'

ActiveRecord::Base.send :include, CollectiveIdea::Acts::Geocodable
ActionController::Base.send :include, CollectiveIdea::RemoteLocation
