require File.join(File.dirname(__FILE__), 'test_helper')

class Vacation < ActiveRecord::Base
  acts_as_geocodable :normalize_address => true
end

class City < ActiveRecord::Base
  acts_as_geocodable
  
  def full_address
    zip
  end
end

class ActsAsGeocodableTest < Test::Unit::TestCase
  fixtures :vacations, :cities, :geocodes, :geocodings
  
  def test_full_address
    whitehouse = vacations(:whitehouse)
    expected_address = "1600 Pennsylvania Ave NW\nWashington, DC 20502"
    assert_equal expected_address, whitehouse.full_address
    
    holland = cities(:holland)
    assert_equal '49423', holland.full_address
  end
  
  def test_geocode_creation_with_address_normalization
    assert Vacation.acts_as_geocodable_options[:normalize_address]
    
    mystery_spot = save_vacation_to_create_geocode
    
    assert_match /Ignace/, mystery_spot.city
    assert_equal 'MI', mystery_spot.state
  end
  
  def test_geocode_creation_without_address_normalization
    Vacation.write_inheritable_attribute(:acts_as_geocodable_options, {
      :normalize_address => false
    })
    assert !Vacation.acts_as_geocodable_options[:normalize_address]
    
    mystery_spot = save_vacation_to_create_geocode
    
    assert_nil mystery_spot.city
    assert_nil mystery_spot.state
  end
  
  def test_geocode_creation_with_invalid_full_address
    nowhere = cities(:nowhere)
    assert_equal '', nowhere.full_address
    assert_equal 0, nowhere.geocodes.size
    
    assert_no_difference(Geocode, :count) do
      assert_no_difference(Geocoding, :count) do
        # Force Geocode
        nowhere.save!
        nowhere.reload
      end
    end
    
    assert_equal 0, nowhere.geocodes.size
  end
  
  def test_geocode_creation_with_invalid_full_address
    nowhere = cities(:nowhere)
    nowhere.zip = nil
    assert_nil nowhere.full_address
    assert_equal 0, nowhere.geocodes.size
    
    assert_no_difference(Geocode, :count) do
      assert_no_difference(Geocoding, :count) do
        # Force Geocode
        nowhere.save!
        nowhere.reload
      end
    end
    
    assert_equal 0, nowhere.geocodes.size
  end
  
  def test_save_respects_existing_geocode
    saugatuck = vacations(:saugatuck)
    assert_equal 1, saugatuck.geocodes.count
    original_geocode = saugatuck.geocodes.first
    
    assert_no_difference(Geocode, :count) do
      assert_no_difference(Geocoding, :count) do
        saugatuck.save!
        saugatuck.reload
        
        saugatuck.city = 'Beverly Hills'
        saugatuck.zip = '90210'
        saugatuck.save!
        saugatuck.reload
      end
    end
    
    assert_equal 1, saugatuck.geocodes.count
    assert_equal original_geocode, saugatuck.geocodes.first
  end
  
  def test_find_within_radius_of_zip
    nearby = []
    douglas_zip = '49406'
    assert_nil Geocode.find_by_zip(douglas_zip)
    
    assert_difference(Geocode, :count, 1) do
      assert_no_difference(Geocoding, :count) do
        assert_no_difference(Vacation, :count) do
          nearby = Vacation.find_within_radius_of_zip(douglas_zip, 10)
        end
      end
    end
    
    assert_equal 1, nearby.size
    assert_equal vacations(:saugatuck), nearby.first
    
    assert_not_nil nearby.first.distance
    assert_in_delta 0.794248231790402, nearby.first.distance.to_f, 0.2
  end
  
  #
  # Helpers
  #
  def save_vacation_to_create_geocode
    mystery_spot = vacations(:mystery_spot)
    assert_equal 0, mystery_spot.geocodes.count
    assert_nil mystery_spot.city
    assert_nil mystery_spot.state
    
    assert_difference(Geocode, :count, 1) do
      mystery_spot.save!
      mystery_spot.reload
    end
    assert_equal 1, mystery_spot.geocodes.count
    mystery_spot
  end
end
