class Graticule::Geocoder::Canned
  class_attribute :responses
  self.responses = {}
  class_attribute :default
  
  def locate(query)
    location = responses[query.to_s.strip]
    raise %Q{No Location for query: "#{query.to_s.inspect}" Add it to spec/support/geocoder.rb} unless location
    location
  end
end

Geocode.geocoder = Graticule::Geocoder::Canned.new

saugatuck = Graticule::Location.new(
  :locality => "Saugatuck",
  :region => "MI",
  :country => "USA",
  :precision => :street,
  :latitude => 42.654781,
  :longitude => -86.200722,
  :postal_code => 49406
)

sf = Graticule::Location.new(
  :locality => "San Francisco",
  :region => "CA",
  :country => "USA",
  :precision => :street,
  :latitude => 37.775206,
  :longitude => -122.419209,
  :postal_code => 94110
)

Geocode.geocoder.responses = {
  'San Francisco'       => sf, 
  'San Francisco, CA'   => sf, 

  '49406'               => saugatuck,
  'Saugatuck, MI'       => saugatuck,
  'Saugatuck, MI 49406' => saugatuck,
  
  "1600 Pennsylvania Ave NW\nWashington, DC 20502" => Graticule::Location.new(
    :locality => "Washington",
    :region => "DC",
    :country => "USA",
    :precision => :street,
    :latitude => 38.898748,
    :longitude => -77.037684,
    :postal_code => '20502'
  )
}