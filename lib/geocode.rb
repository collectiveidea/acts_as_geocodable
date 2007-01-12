class Geocode < ActiveRecord::Base
  include Comparable

  has_many :geocodings
  
  validates_uniqueness_of :query
  before_save :geocode
  
  cattr_accessor :geocoder
  
  def self.geocode(location)
    result = geocoder.locate(location)
    
    # Yahoo Geocoder returns and array of possibilities.  We take the first one.
    if result.is_a? Array
      result = result.first
    end
    
    # Beautify some strings
    result.street = result.street.titleize if result.street
    result.city = result.city.titleize if result.city

    result
  rescue
    # Geocoder threw exception
    return nil
  end

  def distance_to(destination, units = :miles, formula = :haversine)
    "Graticule::Distance::#{formula.to_s.titleize}".constantize.distance(self, destination, units)
  end

  def geocoded?
    !latitude.blank? && !longitude.blank?
  end
  
  # Set the latitude and longitude.
  def geocode
    geocoded_location = Geocode.geocode query
    
    unless geocoded_location.nil?     
      self.latitude  = geocoded_location.latitude
      self.longitude = geocoded_location.longitude
      
      self.street = geocoded_location.street if geocoded_location.street
      self.city = geocoded_location.city if geocoded_location.city
      self.region = geocoded_location.state if geocoded_location.state
      self.postal_code = geocoded_location.zip if geocoded_location.zip
      self.country = geocoded_location.country if geocoded_location.country
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