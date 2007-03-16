class Geocode < ActiveRecord::Base
  include Comparable

  has_many :geocodings
  
  validates_uniqueness_of :query
  before_save :geocode
  
  cattr_accessor :geocoder
  
  def distance_to(destination, units = :miles, formula = :haversine)
    if destination && destination.latitude && destination.longitude
      Graticule::Distance.const_get(formula.to_s.camelize).distance(self, destination, units)
    end
  end

  def geocoded?
    !latitude.blank? && !longitude.blank?
  end
  
  # Set the latitude and longitude.
  def geocode
    logger.debug "lookup up geocode for '#{query}'"
    geocoded_location = self.class.geocoder.locate query
    # Yahoo Geocoder returns and array of possibilities.  We take the first one.
    geocoded_location = geocoded_location.first if geocoded_location.is_a?(Array)
    
    unless geocoded_location.nil?     
      self.latitude  = geocoded_location.latitude
      self.longitude = geocoded_location.longitude
      
      # Beautify some strings
      self.street = geocoded_location.street.titleize if geocoded_location.street
      self.city = geocoded_location.city.titleize if geocoded_location.city
      self.region = geocoded_location.state if geocoded_location.state
      self.postal_code = geocoded_location.zip if geocoded_location.zip
      self.country = geocoded_location.country if geocoded_location.country
      self
    else
      # Halt callback
      false
    end
  end
 
  def geocoded
    @geocoded ||= geocodings.collect { |geocoding| geocoding.geocodable }
  end
  
  def on(geocodable)
    geocodings.create :geocodable => geocodable
  end
  
  def <=>(comparison_object)
    self.to_s <=> comparison_object.to_s
  end
  
  def coordinates
    "#{longitude},#{latitude}"
  end

  def to_s
    coordinates
  end
end