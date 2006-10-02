require File.join(File.dirname(__FILE__), 'test_helper')


class GeocodeTest < Test::Unit::TestCase
  fixtures :geocodes
  
  @@earth_radius_in_miles = 3963.1676
  @@earth_radius_in_kilometers = 6378.135

  
  def test_earth_radius
    assert_equal @@earth_radius_in_miles, Geocode.earth_radius
    assert_equal @@earth_radius_in_miles, Geocode.earth_radius(:miles)
    assert_equal @@earth_radius_in_kilometers, Geocode.earth_radius(:kilometers)
  end
 
  def test_class_geocode
    result = Geocode.geocode('Holland, MI')
    assert_geocode_result result
  end
  
  def test_instance_geocode
    result = nil
    
    assert_difference(Geocode, :count, 1) do
      result = Geocode.create(:query => 'Holland, MI')
      assert_geocode_result result
    end
    
    # Ensure that when we query with the same value, we don't create a new Geocode
    assert_no_difference(Geocode, :count) do
      duplicate = Geocode.find_or_create_by_query('Holland, MI')
      assert_equal result, duplicate
    end
  end
  
  def test_empty_query
    assert_no_difference(Geocode, :count) do
      empty = Geocode.create(:query => '')
      assert empty.new_record?
    end
  end
  
  #
  # Helpers
  #
  def assert_geocode_result(result)
    assert_not_nil result
    assert_kind_of Float, result.latitude
    assert_kind_of Float, result.longitude
    
    # Depending on the geocoder, we'll get slightly different results
    assert_in_delta 42.787567, result.latitude, 0.001
    assert_in_delta -86.109039, result.longitude, 0.001
  end
end