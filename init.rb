require 'rubygems'
require 'graticule'

require 'acts_as_geocodable'
ActiveRecord::Base.send(:include, CollectiveIdea::Acts::Geocodable)

require File.dirname(__FILE__) + '/lib/geocoding'
require File.dirname(__FILE__) + '/lib/geocode'