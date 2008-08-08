require File.join(File.dirname(__FILE__), 'test_helper')

class Vacation < ActiveRecord::Base
  acts_as_geocodable :normalize_address => true
  belongs_to :nearest_city, :class_name => 'City', :foreign_key => 'city_id'
end

class City < ActiveRecord::Base
  acts_as_geocodable :address => {:postal_code => :zip}  
end

class ValidatedVacation < ActiveRecord::Base
  acts_as_geocodable
  validates_as_geocodable
end

class AddressBlobVacation < ActiveRecord::Base
  acts_as_geocodable :address => :address, :normalize_address => true
end

class ActsAsGeocodableTest < Test::Unit::TestCase
  fixtures :vacations, :cities, :geocodes, :geocodings
  
  def test_acts_as_geocodable_declaration
    assert vacations(:whitehouse).respond_to?(:acts_as_geocodable_options)
  end
  
  def test_declaration_adds_geocoding_association
    geocoding = Vacation.reflect_on_association(:geocoding)
    assert_not_nil geocoding
    assert_equal :has_one, geocoding.macro
    assert_equal :geocoding, geocoding.name
    assert_equal 'Geocoding', geocoding.class_name
  end
  
  def test_declaration_adds_geocode_geocode_method
    vacation = vacations(:whitehouse)
    assert_equal vacation.geocoding.geocode, vacation.geocode
  end

  def test_geocode_method_without_geocoding
    assert_nil Vacation.new.geocode
  end

  def test_to_location_full_address
    expected = Graticule::Location.new :street => '1600 Pennsylvania Ave NW',
      :locality => 'Washington', :region => 'DC', :postal_code => '20502',
      :country => nil
    assert_equal expected, vacations(:whitehouse).to_location
  end
  
  def test_to_location_partial_address
    assert_equal Graticule::Location.new(:postal_code => '49423'),
      cities(:holland).to_location
  end
  
  def test_geocode_creation_with_address_normalization
    Geocode.geocoder.expects(:locate).returns(Graticule::Location.new(:locality => "Ignace", :region => "MI"))

    assert Vacation.acts_as_geocodable_options[:normalize_address]

    mystery_spot = save_vacation_to_create_geocode

    assert_match /Ignace/, mystery_spot.locality
    assert_equal 'MI', mystery_spot.region
  end
  
  def test_geocode_creation_without_address_normalization
    Vacation.acts_as_geocodable_options.merge! :normalize_address => false
    assert !Vacation.acts_as_geocodable_options[:normalize_address]
    
    mystery_spot = save_vacation_to_create_geocode
    
    assert_nil mystery_spot.locality
    assert_nil mystery_spot.region
  end

  def test_geocode_creation_with_empty_attributes
    nowhere = cities(:nowhere)
    assert nowhere.to_location.attributes.empty?
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
  
  def test_geocode_creation_with_whitespace_attributes
    nowhere = cities(:nowhere)
    nowhere.zip = "\n"
    assert nowhere.to_location.attributes.empty?
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
  
  def test_geocode_creation_with_nil_attributes
    nowhere = cities(:nowhere)
    nowhere.zip = nil
    assert nowhere.to_location.attributes.empty?
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
    whitehouse = vacations(:whitehouse)
    assert_not_nil whitehouse.geocoding
    original_geocode = whitehouse.geocode
    
    assert_no_difference(Geocode, :count) do
      assert_no_difference(Geocoding, :count) do
        whitehouse.save!
        whitehouse.reload
      end
    end
    
    assert_equal original_geocode, whitehouse.geocode
  end
  
  
  def test_save_blank_location_destroys_geocoding
    whitehouse = vacations(:whitehouse)
    assert_not_nil whitehouse.geocoding
    [:name, :street, :locality, :region, :postal_code].each do |attribute|
      whitehouse.send("#{attribute}=", nil)
    end
    
    assert_no_difference(Geocode, :count) do
      assert_difference(Geocoding, :count, -1) do
        whitehouse.save!
        whitehouse.reload
      end
    end
    
    assert whitehouse.geocode.nil?
  end
  
  def test_validates_as_geocodable_fails
    Geocode.geocoder.expects(:locate).raises(Graticule::Error)
    vacation = ValidatedVacation.new
    assert !vacation.valid?
    assert_equal 1, vacation.errors.size
    assert_equal "Address could not be geocoded.", vacation.errors.on(:base)
  end
  
  def test_validates_as_geocodable_passes
    vacation = ValidatedVacation.new :locality => "Grand Rapids", :region => "MI"
    assert vacation.valid?
  end
    
  def test_normalize_address_with_address_blob
    Geocode.geocoder.expects(:locate).returns(Graticule::Location.new(:locality => "Grand Rapids", :region => "MI", :country => "US"))
    
    vacation = AddressBlobVacation.new :address => "grand rapids, mi"
    assert vacation.save
    assert_equal "Grand Rapids, MI US", vacation.address
  end
    

  def test_updates_geocode_on_save
    saugatuck = vacations(:saugatuck)
    assert_not_nil saugatuck.geocoding
    original_geocode = saugatuck.geocode
    
    assert_no_difference(Geocoding, :count) do
      saugatuck.locality = 'Beverly Hills'
      saugatuck.postal_code = '90210'
      saugatuck.save!
      saugatuck.reload
    end
    
    assert_equal geocodes(:beverly_hills), saugatuck.geocode
  end
  
  # def test_find_within_radius_of_postal_code
  #   douglas_postal_code = '49406'
  #   
  #   assert_no_difference(Geocoding, :count) do
  #     assert_no_difference(Vacation, :count) do
  #       nearby = Vacation.find_within_radius_of_postal_code(douglas_postal_code, 10)
  # 
  #       assert_equal 1, nearby.size
  #       assert_equal vacations(:saugatuck), nearby.first
  # 
  #       assert_not_nil nearby.first.distance
  #       assert_in_delta 0.794248231790402, nearby.first.distance.to_f, 0.2
  #     end
  #   end
  # end
  # 
  # def test_find_all_within_radius
  #   douglas = Geocode.find_by_postal_code '49406'
  #   nearby = Vacation.find_all_within_radius douglas, 10
  #   assert_equal 1, nearby.size
  # end
  
  def test_distance_to
    saugatuck = vacations(:saugatuck)
    douglas = Vacation.create(:name => 'Douglas', :postal_code => '49406')
    douglas.reload # reload to get geocode
    
    distance = douglas.distance_to(saugatuck)
    assert_in_delta 0.794248231790402, distance, 0.2
    
    distance = saugatuck.distance_to(douglas)
    assert_in_delta 0.794248231790402, distance, 0.2
    
    distance = douglas.distance_to(saugatuck, :units => :miles)
    assert_in_delta 0.794248231790402, distance, 0.2
    
    distance = douglas.distance_to(saugatuck, :units => :kilometers)
    assert_in_delta 1.27821863, distance, 0.2
  end
  
  def test_find_adds_distance_to_model
    saugatuck = Vacation.find(1, :origin => "49406")
    assert_in_delta 0.794248231790402, saugatuck.distance, 0.2
  end
  
  def test_find_within
    spots = Vacation.find(:all, :origin => "49406", :within => 3)
    assert_equal 1, spots.size
    assert_equal vacations(:saugatuck), spots.first
  end
  
  def test_count_within
    spots_count = Vacation.count(:origin => "49406", :within => 3)
    assert_equal 1, spots_count
  end
  
  def test_within_kilometers
    saugatuck = Vacation.find(:first, :within => 2, :units => :kilometers, :origin => "49406")
    assert_equal vacations(:saugatuck), saugatuck
    assert_in_delta 1.27821863, saugatuck.distance, 0.2
  end
  
  def test_find_beyond
    spots = Vacation.find(:all, :origin => "49406", :beyond => 3)
    assert_equal 1, spots.size
    assert_equal vacations(:whitehouse), spots.first
  end

  def test_count_beyond
    spots = Vacation.count(:origin => "49406", :beyond => 3)
    assert_equal 1, spots
  end

  def test_find_beyond_in_kilometers
    whitehouse = Vacation.find(:first, :beyond => 3, :units => :kilometers, :origin => "49406")
    assert_equal vacations(:whitehouse), whitehouse
    assert_in_delta 877.554975851074, whitehouse.distance, 1
  end
  
  def test_find_nearest
    assert_equal vacations(:saugatuck), Vacation.find(:nearest, :origin => "49406")
  end
  
  def test_find_nearest
    assert_equal vacations(:whitehouse), Vacation.find(:farthest, :origin => "49406")
  end
  
  def test_find_nearest_with_include_raises_error
    assert_raises(ArgumentError) { Vacation.find(:nearest, :origin => '49406', :include => :nearest_city) }
  end
  
  def test_uses_units_set_in_declared_options
    Vacation.acts_as_geocodable_options.merge! :units => :kilometers
    saugatuck = Vacation.find(:first, :within => 2, :units => :kilometers, :origin => "49406")
    assert_in_delta 1.27821863, saugatuck.distance, 0.2
  end
  
  def test_find_with_order
    expected = [vacations(:saugatuck), vacations(:whitehouse)]
    actual = Vacation.find(:all, :origin => '49406', :order => 'distance')
    assert_equal expected, actual
  end
  
  def test_location_to_geocode_nil
    assert_nil Vacation.send(:location_to_geocode, nil)
  end
  
  def test_location_to_geocode_with_geocode
    g = Geocode.new
    assert(g === Vacation.send(:location_to_geocode, g))
  end
  
  def test_location_to_geocode_with_string
    assert_equal geocodes(:douglas), Vacation.send(:location_to_geocode, '49406')
  end

  def test_location_to_geocode_with_fixnum
    assert_equal geocodes(:douglas), Vacation.send(:location_to_geocode, 49406)
  end
  
  def test_location_to_geocode_with_geocodable
    assert_equal geocodes(:white_house_geocode),
      Vacation.send(:location_to_geocode, vacations(:whitehouse))
  end
  
  def test_find_nearest_raises_error_with_include
    assert_raises(ArgumentError) { Vacation.find(:nearest, :include => :nearest_city, :origin => 49406) }
  end
  
private
  
  def save_vacation_to_create_geocode
    returning vacations(:mystery_spot) do |mystery_spot|
      assert mystery_spot.geocode.blank?
      assert_nil mystery_spot.locality
      assert_nil mystery_spot.region

      assert_difference(Geocode, :count, 1) do
        mystery_spot.save!
        mystery_spot.reload
      end
      assert_not_nil mystery_spot.geocode
    end
  end
  
end
