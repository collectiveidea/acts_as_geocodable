require File.join(File.dirname(__FILE__), 'test_helper')
require 'shoulda/rails'

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

class CallbackLocation < ActiveRecord::Base
  acts_as_geocodable :address => :address
  after_geocoding :done_geocoding
  
  def done_geocoding
    true
  end
end

class ActsAsGeocodableTest < ActiveSupport::TestCase
  fixtures :vacations, :cities, :geocodes, :geocodings

  # enable Should macros
  def self.model_class
    Vacation
  end
  
  should_have_one :geocoding
  
  context "geocode" do
    setup do
      @location = vacations(:whitehouse)
    end

    should "be the geocode from the geocoding" do
      @location.geocode.should == @location.geocoding.geocode
    end
    
    should "be nil without a geocoding" do
      Vacation.new.geocode.should be(nil)
    end
    
  end
  
  context "to_location" do
    should "return a graticule location" do
      expected = Graticule::Location.new :street => '1600 Pennsylvania Ave NW',
        :locality => 'Washington', :region => 'DC', :postal_code => '20502',
        :country => nil
      vacations(:whitehouse).to_location.should == expected
    end
    
    should "return a graticule location for mapped locations" do
      cities(:holland).to_location.should == Graticule::Location.new(:postal_code => '49423')
    end
  end
  
  context "with address normalization" do
    setup do
      Vacation.acts_as_geocodable_options[:normalize_address] = true
      
      Geocode.geocoder.stubs(:locate).returns(
        Graticule::Location.new(:locality => "San Clemente", :region => "CA")
      )
    end

    should "update address fields with result" do
      vacation = Vacation.create! :locality => 'sanclemente', :region => 'ca'
      vacation.locality.should == 'San Clemente'
      vacation.region.should == 'CA'
    end
    
    should "update address blob" do
      Geocode.geocoder.expects(:locate).returns(
        Graticule::Location.new(:locality => "Grand Rapids", :region => "MI", :country => "US")
      )

      vacation = AddressBlobVacation.create! :address => "grand rapids, mi"
      vacation.address.should == "Grand Rapids, MI US"
    end
    
  end
  
  context "without address normalization" do
    setup do
      Vacation.acts_as_geocodable_options[:normalize_address] = false
      
      Geocode.geocoder.stubs(:locate).returns(
        Graticule::Location.new(:locality => "Portland", :region => "OR", :postal_code => '97212')
      )
      
      @vacation = Vacation.create! :locality => 'portland', :region => 'or'
    end

    should "not update address attributes" do
      @vacation.locality.should == 'portland'
      @vacation.region.should == 'or'
    end
    
    should "fill in blank attributes" do
      @vacation.postal_code.should == '97212'
    end
  end
  
  context "with blank location attributes" do
    should "not create geocode" do
      Geocode.geocoder.expects(:locate).never
      assert_no_difference 'Geocode.count + Geocoding.count' do
        Vacation.create!(:locality => "\n", :region => " ").geocoding.should be(nil)
      end
    end

    should "destroy existing geocoding" do
      whitehouse = vacations(:whitehouse)
      [:name, :street, :locality, :region, :postal_code].each do |attribute|
        whitehouse.send("#{attribute}=", nil)
      end
      assert_difference 'Geocoding.count', -1 do
        whitehouse.save!
      end
      whitehouse.reload
      whitehouse.geocoding.should be(nil)
    end
  end

  context "on save" do
    should "not create geocode without changes" do
      whitehouse = vacations(:whitehouse)
      assert_not_nil whitehouse.geocoding
      original_geocode = whitehouse.geocode
    
      assert_no_difference 'Geocode.count + Geocoding.count' do
        whitehouse.save!
        whitehouse.reload
      end
    
      assert_equal original_geocode, whitehouse.geocode
    end
    
  end
  
  context "on save with an existing geocode" do
    setup do
      @location = vacations(:saugatuck)
      @location.attributes = {:locality => 'Beverly Hills', :postal_code => '90210'}
    end
    
    should "destroy the old geocoding" do
      assert_no_difference('Geocoding.count') { @location.save! }
    end

    should "set the new geocode" do
      @location.save!
      @location.geocode.should == geocodes(:beverly_hills)
    end
    
  end
  
  context "validates_as_geocodable" do
    setup do
      @vacation = ValidatedVacation.new :locality => "Grand Rapids", :region => "MI"
    end

    should "be invalid without geocodable address" do
      Geocode.geocoder.expects(:locate).raises(Graticule::Error)
      assert !@vacation.valid?
      assert_equal 1, @vacation.errors.size
      assert_equal "Address could not be geocoded.", @vacation.errors.on(:base)
    end
    
    should "be valid with geocodable address" do
      assert @vacation.valid?
    end
  end
  
  context "find with origin" do
    should "add distance to result" do
      Vacation.find(1, :origin => "49406").distance.to_f.should be_close(0.794248231790402, 0.2)
    end
  end
  
  context "find within" do
    setup do
      @results = Vacation.find(:all, :origin => 49406, :within => 10)
    end
    
    should "find locations within radius" do
      @results.should include(vacations(:saugatuck))
    end
    
    should "add distance to results" do
      @results.first.distance.to_f.should be_close(0.794248231790402, 0.2)
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
    
  end
  
  context "distance_to" do
    setup do
      @saugatuck = vacations(:saugatuck)
      @douglas = Vacation.create!(:name => 'Douglas', :postal_code => '49406')
    end

    should 'calculate distance from a string' do
      @douglas.distance_to(geocodes(:saugatuck_geocode).query).should be_close(0.794248231790402, 0.2)
    end
    should 'calculate distance from a geocode' do
      @douglas.distance_to(geocodes(:saugatuck_geocode)).should be_close(0.794248231790402, 0.2)
    end

    should 'calculate distance from a geocodable model' do
      @douglas.distance_to(@saugatuck).should be_close(0.794248231790402, 0.2)
      @saugatuck.distance_to(@douglas).should be_close(0.794248231790402, 0.2)
    end

    should 'calculate distance in default miles' do
      @douglas.distance_to(@saugatuck, :units => :miles).should be_close(0.794248231790402, 0.2)
    end
    
    should 'calculate distance in default kilometers' do
      @douglas.distance_to(@saugatuck, :units => :kilometers).should be_close(1.27821863, 0.2)
    end
    
    should 'return nil with invalid geocode' do
      @douglas.distance_to(Geocode.new).should be(nil)
      @douglas.distance_to(nil).should be(nil)
    end
    
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
  
  def test_callback_after_geocoding
    location = CallbackLocation.new :address => "Holland, MI"
    assert_nil location.geocoding
    location.expects(:done_geocoding).once.returns(true)
    assert location.save!
  end

  def test_does_not_run_the_callback_after_geocoding_if_object_dont_change
    location = CallbackLocation.create(:address => "Holland, MI")
    assert_not_nil location.geocoding
    location.expects(:done_geocoding).never
    assert location.save!
  end
  
  
end
