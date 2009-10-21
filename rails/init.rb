require 'graticule'
require 'acts_as_geocodable'

ActiveRecord::Base.send :include, CollectiveIdea::Acts::Geocodable
ActionController::Base.send :include, CollectiveIdea::RemoteLocation