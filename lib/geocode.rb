class Geocode < ActiveRecord::Base
  include Comparable
  
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
    result.street = result.street.titleize if result.street
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
    first_longitude = self.deg2rad(first.longitude)
    first_latitude = self.deg2rad(first.latitude)
    second_longitude = self.deg2rad(second.longitude)
    second_latitude = self.deg2rad(second.latitude)
    
    Math.acos(
        Math.cos(first_longitude) *
        Math.cos(second_longitude) * 
        Math.cos(first_latitude) * 
        Math.cos(second_latitude) +
         
        Math.cos(first_latitude) *
        Math.sin(first_longitude) *
        Math.cos(second_latitude) *
        Math.sin(second_longitude) +
        
        Math.sin(first_latitude) *
        Math.sin(second_latitude)
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