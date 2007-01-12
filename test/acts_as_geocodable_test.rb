require File.join(File.dirname(__FILE__), 'test_helper')

class Vacation < ActiveRecord::Base
  acts_as_geocodable :normalize_address => true
end

class City < ActiveRecord::Base
  acts_as_geocodable :address => {:postal_code => :zip}  
end

class ActsAsGeocodableTest < Test::Unit::TestCase
  fixtures :vacations, :cities, :geocodes, :geocodings
  
  def test_acts_as_geocodable_declaration
    assert vacations(:whitehouse).respond_to?(:acts_as_geocodable_options)
    assert vacations(:whitehouse).respond_to?(:geocoding)
    assert vacations(:whitehouse).respond_to?(:geocode)
  end
  
  def test_full_address
    whitehouse = vacations(:whitehouse)
    expected_address = "1600 Pennsylvania Ave NW\nWashington, DC 20502"
    assert_equal expected_address, whitehouse.full_address
    
    holland = cities(:holland)
    assert_equal '49423', holland.full_address
  end
  
  # FIXME: this test is failing, why?
  # def test_geocode_creation_with_address_normalization
  #   assert Vacation.acts_as_geocodable_options[:normalize_address]
  # 
  #   mystery_spot = save_vacation_to_create_geocode
  # 
  #   assert_match /Ignace/, mystery_spot.city
  #   assert_equal 'MI', mystery_spot.region
  # end
  
  def test_geocode_creation_without_address_normalization
    Vacation.acts_as_geocodable_options.merge! :normalize_address => false
    assert !Vacation.acts_as_geocodable_options[:normalize_address]
    
    mystery_spot = save_vacation_to_create_geocode
    
    assert_nil mystery_spot.city
    assert_nil mystery_spot.region
  end

  def test_geocode_creation_with_empty_full_address
    nowhere = cities(:nowhere)
    assert_equal '', nowhere.full_address
    assert_nil nowhere.geocode
    
    assert_no_difference(Geocode, :count) do
      assert_no_difference(Geocoding, :count) do
        # Force Geocode
        nowhere.save!
        nowhere.reload
      end
    end
    
    assert_nil nowhere.geocoding
  end
  
  def test_geocode_creation_with_nil_full_address
    nowhere = cities(:nowhere)
    nowhere.zip = nil
    assert nowhere.full_address.empty?
    assert_nil nowhere.geocode
    
    assert_no_difference(Geocode, :count) do
      assert_no_difference(Geocoding, :count) do
        # Force Geocode
        nowhere.save!
        nowhere.reload
      end
    end
    
    assert_nil nowhere.geocoding
  end
  
  def test_save_without_change_does_not_create_geocode
    saugatuck = vacations(:saugatuck)
    assert_not_nil saugatuck.geocoding
    original_geocode = saugatuck.geocode
    
    assert_no_difference(Geocode, :count) do
      assert_no_difference(Geocoding, :count) do
        saugatuck.save!
        saugatuck.reload
      end
    end
    
    assert_equal original_geocode, saugatuck.geocode
  end

  def test_updates_geocode_on_save
    saugatuck = vacations(:saugatuck)
    assert_not_nil saugatuck.geocoding
    original_geocode = saugatuck.geocode
    
    assert_no_difference(Geocoding, :count) do
      saugatuck.city = 'Beverly Hills'
      saugatuck.postal_code = '90210'
      saugatuck.save!
      saugatuck.reload
    end
    
    assert_equal geocodes(:beverly_hills), saugatuck.geocode
  end
  
  def test_find_within_radius_of_postal_code
    douglas_postal_code = '49406'
    
    assert_no_difference(Geocoding, :count) do
      assert_no_difference(Vacation, :count) do
        nearby = Vacation.find_within_radius_of_postal_code(douglas_postal_code, 10)

        assert_equal 1, nearby.size
        assert_equal vacations(:saugatuck), nearby.first

        assert_not_nil nearby.first.distance
        assert_in_delta 0.794248231790402, nearby.first.distance.to_f, 0.2
      end
    end
  end
  
  def test_find_all_within_radius
    douglas = Geocode.find_by_postal_code '49406'
    nearby = Vacation.find_all_within_radius douglas, 10
    assert_equal 1, nearby.size
  end
  
  def test_distance_to
    saugatuck = vacations(:saugatuck)
    douglas = Vacation.create(:name => 'Douglas', :postal_code => '49406')
    douglas.reload # reload to get geocode
    
    distance = douglas.distance_to(saugatuck)
    assert_in_delta 0.794248231790402, distance, 0.2
    
    distance = saugatuck.distance_to(douglas)
    assert_in_delta 0.794248231790402, distance, 0.2
    
    distance = douglas.distance_to(saugatuck, :miles)
    assert_in_delta 0.794248231790402, distance, 0.2
    
    distance = douglas.distance_to(saugatuck, :kilometers)
    assert_in_delta 1.27821863, distance, 0.2
  end
  
  #
  # Helpers
  #
  def save_vacation_to_create_geocode
    returning vacations(:mystery_spot) do |mystery_spot|
      assert mystery_spot.geocode.blank?
      assert_nil mystery_spot.city
      assert_nil mystery_spot.region

      assert_difference(Geocode, :count, 1) do
        mystery_spot.save!
        mystery_spot.reload
      end
      assert_not_nil mystery_spot.geocode
    end
  end
end
