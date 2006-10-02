class Geocode < ActiveRecord::Base
  has_many :geocodings
  
  validates_uniqueness_of :query
  before_save :geocode
  
  cattr_accessor :geocoder
  
  def self.geocode location
    result = geocoder.locate(location)
    
    # Yahoo Geocoder returns and array of possibilities.  We take the first one.
    if result.is_a? Array
      result = result.first
    end
    
    # Beautify some strings
    result.address = result.address.titleize if result.address
    result.city = result.city.titleize if result.city

    result
  rescue
    # Geocoder threw exception
    return nil
  end
  
  def self.earth_radius(units=:miles)
    if units == :kilometers
      6378.135
    else
      3963.1676
    end
  end
  
  # Set the latitude and longitude.
  def geocode    
    geocoded_location = Geocode.geocode query

    unless geocoded_location.nil?     
      self.latitude  = geocoded_location.latitude
      self.longitude = geocoded_location.longitude
      
      self.street = geocoded_location.address if geocoded_location.address
      self.city = geocoded_location.city if geocoded_location.city
      self.state = geocoded_location.state if geocoded_location.state
      self.zip = geocoded_location.zip if geocoded_location.zip
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
  
  def ==(comparison_object)
    super || self.to_s == comparison_object.to_s
  end
  
  def <=>(comparison_object)
    self.to_s <=> comparison_object.to_s
  end
  
  def to_s
    longitude+', '+latitude
  end
  
  def to_param
    longitude+','+latitude
  end
end