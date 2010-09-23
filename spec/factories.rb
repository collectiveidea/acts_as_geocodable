Factory.define :chicago, :class => City do |c|
  c. ''
  c.zip ''
  c.name 'Chicago'
end

Factory.define :holland, :class => City do |c|
  c. ''
  c.zip 49423
  c.name 'Holland'
end

Factory.define :nowhere, :class => City do |c|
  c. ''
  c.zip ''
  c.name 'Nowhere'
end

Factory.define :chicago_geocode, :class => Geocode do |g|
  g.query 'Chicago, IL'
  g.longitude -87.65
  g.locality 'Chicago'
  g. ''
  g.postal_code ''
  g.latitude 41.85
  g.region 'IL'
end

Factory.define :white_house_geocode, :class => Geocode do |g|
  g.query 1600 Pennsylvania Ave NW
Washington, DC 20502
  g.longitude -77.037684
  g.locality 'Washington'
  g. ''
  g.street 1600 Pennsylvania Ave NW
  g.postal_code 20502
  g.latitude 38.898748
  g.region 'DC'
end

Factory.define :saugatuck_geocode, :class => Geocode do |g|
  g.query 'Saugatuck, MI'
  g.longitude -86.200722
  g.locality 'Saugatuck'
  g. ''
  g.latitude 42.654781
  g.region 'MI'
end

Factory.define :douglas, :class => Geocode do |g|
  g.query 49406
  g.longitude -86.2005
  g.locality 'Douglas'
  g. ''
  g.postal_code 49406
  g.country 'US'
  g.latitude 42.6433
  g.region 'MI'
end

Factory.define :beverly_hills, :class => Geocode do |g|
  g.query 'Beverly Hills, 90210'
  g.longitude -118.4098
  g.locality 'Beverly Hills'
  g. ''
  g.postal_code 90210
  g.country 'US'
  g.latitude 34.0924
  g.region 'CA'
end

Factory.define :holland, :class => Geocode do |g|
  g.query 'Holland, MI'
  g.longitude -86.109039
  g.locality 'Holland'
  g. ''
  g.postal_code ''
  g.country 'US'
  g.latitude 42.787567
  g.region 'MI'
end

Factory.define :chicago_geocoding, :class => Geocoding do |g|
  g.geocode_id 3
  g. ''
  g.geocodable_id 1
  g.geocodable_type 'City'
end

Factory.define :white_house_geocoding, :class => Geocoding do |g|
  g.geocode_id 2
  g. ''
  g.geocodable_id 2
  g.geocodable_type 'Vacation'
end

Factory.define :saugatuck_geocoding, :class => Geocoding do |g|
  g.geocode_id 1
  g. ''
  g.geocodable_id 1
  g.geocodable_type 'Vacation'
end

Factory.define :saugatuck, :class => Vacation do |v|
  v. ''
  v.name 'Saugatuck, Michigan'
end

Factory.define :whitehouse, :class => Vacation do |v|
  v.locality 'Washington'
  v. ''
  v.street 1600 Pennsylvania Ave NW
  v.postal_code 20502
  v.name 'The White House'
  v.region 'DC'
end

Factory.define :mystery_spot, :class => Vacation do |v|
  v. ''
  v.street 150 Martin Lake Rd.
  v.postal_code 49781
  v.name 'The Mystery Spot'
end

