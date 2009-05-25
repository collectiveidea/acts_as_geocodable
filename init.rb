begin 
  require 'graticule'
rescue LoadError
  raise "Graticule >= 0.2.0 is required for acts_as_geocodable"
end
require 'acts_as_geocodable'

ActiveRecord::Base.send :include, CollectiveIdea::Acts::Geocodable
ActionController::Base.send :include, CollectiveIdea::RemoteLocation