class Geocode < ActiveRecord::Base
  has_many :geocodings, :dependent => :destroy

  validates_uniqueness_of :query

  cattr_accessor :geocoder

  def distance_to(destination, units = :miles, formula = :haversine)
    if destination && destination.latitude && destination.longitude
      Graticule::Distance.const_get(formula.to_s.camelize).distance(self, destination, units)
    end
  end

  def geocoded?
    !latitude.blank? && !longitude.blank?
  end

  def self.find_or_create_by_query(query)
    find_by_query(query.to_s.downcase) || create_by_query(query)
  end

  def self.create_by_query(query)
    create geocoder.locate(query).attributes.merge(:query => query.to_s.downcase)
  end

  def self.find_or_create_by_location(location)
    find_by_query(location.to_s.downcase) || create_from_location(location)
  end

  def self.create_from_location(location)
    create geocoder.locate(location).attributes.merge(:query => location.to_s.downcase)
  rescue Graticule::Error => e
    logger.warn e.message
    nil
  end

  def precision
    Graticule::Precision.new(self[:precision])
  end

  def precision=(name)
    self[:precision] = name.to_s
  end

  def geocoded
    @geocoded ||= geocodings.collect { |geocoding| geocoding.geocodable }
  end

  def on(geocodable)
    geocodings.create :geocodable => geocodable
  end

  def coordinates
    "#{longitude},#{latitude}"
  end

  def to_s
    coordinates
  end

  # Create a Graticule::Location
  def to_location
    Graticule::Location.new(attributes.except('id', 'query'))
  end
end