require 'graticule'
require 'acts_as_geocodable'

ActiveRecord::Base.send :include, ActsAsGeocodable
ActionController::Base.send :include, ActsAsGeocodable::RemoteLocation