require 'graticule'
require 'acts_as_geocodable'

ActiveRecord::Base.send :extend, ActsAsGeocodable
ActionController::Base.send :include, ActsAsGeocodable::RemoteLocation