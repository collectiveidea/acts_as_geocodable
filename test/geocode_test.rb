require File.join(File.dirname(__FILE__), 'test_helper')


class GeocodeTest < Test::Unit::TestCase
  fixtures :geocodes
  
  def test_distance_to
    washington_dc = geocodes(:white_house_geocode)
    chicago = geocodes(:chicago_geocode)
    
    distance_in_default_units = washington_dc.distance_to(chicago)
    distance_in_miles = washington_dc.distance_to(chicago, :miles)
    distance_in_kilometers = washington_dc.distance_to(chicago, :kilometers)
    
    assert_in_delta 594.820, distance_in_default_units, 1.0
    assert_in_delta 594.820, distance_in_miles, 1.0
    assert_in_delta 957.275, distance_in_kilometers, 1.0
  end
  
  def test_distance_with_invalid_geocode
    chicago = geocodes(:chicago_geocode)
    fake = Geocode.new
    
    assert_nil chicago.distance_to(fake)
    assert_nil chicago.distance_to(nil)
  end
 
  def test_instance_geocode
    result = nil
    
    # Ensure that when we query with the same value, we don't create a new Geocode
    assert_no_difference(Geocode, :count) do
      result = Geocode.find_or_create_by_query('Holland, MI')
      assert_equal geocodes(:holland), result
    end
  end
  
  def test_cooridnates
    assert_equal "-86.200722,42.654781", geocodes(:saugatuck_geocode).coordinates
  end

  def test_to_s
    assert_equal "-86.200722,42.654781", geocodes(:saugatuck_geocode).to_s
  end
  
  def test_geocoded?
    assert Geocode.new(:latitude => 1, :longitude => 1).geocoded?
    assert !Geocode.new(:longitude => 1).geocoded?
    assert !Geocode.new(:latitude => 1).geocoded?
    assert !Geocode.new.geocoded?
  end
  
  def test_find_or_create_by_location_finds_existing_geocode
    location = Graticule::Location.new(:postal_code => "20502",
      :street => "1600 Pennsylvania Ave NW")
    assert_equal geocodes(:white_house_geocode), Geocode.find_or_create_by_location(location)
  end
  
  def test_find_or_create_by_query_finds_existing_geocode
    assert_equal geocodes(:white_house_geocode),
      Geocode.find_or_create_by_query("1600 Pennsylvania Ave NW\n20502")
  end

end