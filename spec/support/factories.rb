FactoryGirl.define do
  factory :chicago, :class => City do
    zip  ''
    name 'Chicago'
  end
  
  factory :holland, :class => City do
    zip  49423
    name 'Holland'
  end
  
  factory :nowhere, :class => City do
    zip  ''
    name 'Nowhere'
  end
  
  factory :chicago_geocode, :class => Geocode do
    query       'Chicago, IL'
    longitude   -87.65
    locality    'Chicago'
    postal_code ''
    latitude    41.85
    region      'IL'
  end
  
  factory :white_house_geocode, :class => Geocode do
    query       "1600 Pennsylvania Ave NW\nWashington, DC 20502"
    longitude   -77.037684
    locality    'Washington'
    street      '1600 Pennsylvania Ave NW'
    postal_code 20502
    latitude    38.898748
    region      'DC'
  end
  
  factory :saugatuck_geocode, :class => Geocode do
    query 'Saugatuck, MI'
    longitude -86.200722
    locality 'Saugatuck'
    latitude 42.654781
    region 'MI'
  end
  
  factory :douglas_geocode, :class => Geocode do
    query 49406
    longitude -86.2005
    locality 'Douglas'
    postal_code 49406
    country 'US'
    latitude 42.6433
    region 'MI'
  end
  
  factory :beverly_hills, :class => Geocode do
    query 'Beverly Hills, 90210'
    longitude -118.4098
    locality 'Beverly Hills'
    postal_code 90210
    country 'US'
    latitude 34.0924
    region 'CA'
  end
  
  factory :holland_geocode, :class => Geocode do
    query 'Holland, MI'
    longitude -86.109039
    locality 'Holland'
    postal_code ''
    country 'US'
    latitude 42.787567
    region 'MI'
  end
  
  factory :chicago_geocoding, :class => Geocoding do
    geocode_id 3
    geocodable_id 1
    geocodable_type 'City'
  end
  
  factory :white_house_geocoding, :class => Geocoding do
    geocode_id 2
    geocodable_id 2
    geocodable_type 'Vacation'
  end
  
  factory :saugatuck_geocoding, :class => Geocoding do
    geocode
    geocodable
  end
  
  factory :saugatuck, :class => Vacation do
    name 'Saugatuck, Michigan'
    locality 'Saugatuck'
    region 'MI'
  end
  
  factory :whitehouse, :class => Vacation do
    locality 'Washington'
    street '1600 Pennsylvania Ave NW'
    postal_code 20502
    name 'The White House'
    region 'DC'
  end
  
  factory :mystery_spot, :class => Vacation do
    street '150 Martin Lake Rd.'
    postal_code 49781
    name 'The Mystery Spot'
  end
end
