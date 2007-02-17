require 'rubygems'
require 'graticule'
require File.dirname(__FILE__) + '/lib/acts_as_geocodable'
require File.dirname(__FILE__) + '/lib/geocoding'
require File.dirname(__FILE__) + '/lib/geocode'

ActiveRecord::Base.send(:include, CollectiveIdea::Acts::Geocodable)