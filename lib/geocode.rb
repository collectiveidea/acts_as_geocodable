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
  
  def self.distance(first, second, units=:miles)
    return false unless first && first.geocoded? && second && second.geocoded?
  
    # TODO: Does anyone have an equation that is either faster or more accurate?
    Math.acos(
        Math.cos(self.deg2rad(first.longitude)) *
        Math.cos(self.deg2rad(second.longitude)) * 
        Math.cos(self.deg2rad(first.latitude)) * 
        Math.cos(self.deg2rad(second.latitude)) +
         
        Math.cos(self.deg2rad(first.latitude)) *
        Math.sin(self.deg2rad(first.longitude)) *
        Math.cos(self.deg2rad(second.latitude)) *
        Math.sin(self.deg2rad(second.longitude)) +
        
        Math.sin(self.deg2rad(first.latitude)) *
        Math.sin(self.deg2rad(second.latitude))
    ) * self.earth_radius(units)
  end
  
  def geocoded?
    !latitude.blank? && !longitude.blank?
  end
  
  def self.deg2rad(deg)
  	(deg * Math::PI / 180)
  end

  def self.rad2deg(rad)
  	(rad * 180 / Math::PI)
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
  
  def coordinates
    "#{longitude},#{latitude}"
  end

  def to_s
    coordinates
  end
end