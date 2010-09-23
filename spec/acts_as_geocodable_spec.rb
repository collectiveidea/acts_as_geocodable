require 'spec_helper'

describe ActsAsGeocodable do
  # fixtures :vacations, :cities, :geocodes, :geocodings

  # # enable Should macros
  # subject { Vacation.new }
  # 
  # should_have_one :geocoding
  
  describe "geocode" do
    before do
      @location = vacations(:whitehouse)
    end

    it "should be the geocode from the geocoding" do
      @location.geocode.should == @location.geocoding.geocode
    end
    
    it "should be nil without a geocoding" do
      Vacation.new.geocode.should be_nil
    end
    
  end
  
  describe "to_location" do
    it "should return a graticule location" do
      expected = Graticule::Location.new :street => '1600 Pennsylvania Ave NW',
        :locality => 'Washington', :region => 'DC', :postal_code => '20502',
        :country => nil
      vacations(:whitehouse).to_location.should == expected
    end
    
    it "should return a graticule location for mapped locations" do
      cities(:holland).to_location.should == Graticule::Location.new(:postal_code => '49423')
    end
  end
  
  describe "with address normalization" do
    before do
      Vacation.acts_as_geocodable_options[:normalize_address] = true
      
      Geocode.geocoder.stubs(:locate).returns(
        Graticule::Location.new(:locality => "San Clemente", :region => "CA")
      )
    end

    it "should update address fields with result" do
      vacation = Vacation.create! :locality => 'sanclemente', :region => 'ca'
      vacation.locality.should == 'San Clemente'
      vacation.region.should == 'CA'
    end
    
    it "should update address blob" do
      Geocode.geocoder.expects(:locate).returns(
        Graticule::Location.new(:locality => "Grand Rapids", :region => "MI", :country => "US")
      )

      vacation = AddressBlobVacation.create! :address => "grand rapids, mi"
      vacation.address.should == "Grand Rapids, MI US"
    end
    
  end
  
  describe "without address normalization" do
    before do
      Vacation.acts_as_geocodable_options[:normalize_address] = false
      
      Geocode.geocoder.stubs(:locate).returns(
        Graticule::Location.new(:locality => "Portland", :region => "OR", :postal_code => '97212')
      )
      
      @vacation = Vacation.create! :locality => 'portland', :region => 'or'
    end

    it "should not update address attributes" do
      @vacation.locality.should == 'portland'
      @vacation.region.should == 'or'
    end
    
    it "should fill in blank attributes" do
      @vacation.postal_code.should == '97212'
    end
  end
  
  describe "with blank location attributes" do
    it "should not create geocode" do
      Geocode.geocoder.expects(:locate).never
      assert_no_difference 'Geocode.count + Geocoding.count' do
        Vacation.create!(:locality => "\n", :region => " ").geocoding.should be_nil
      end
    end

    it "should destroy existing geocoding" do
      whitehouse = vacations(:whitehouse)
      [:name, :street, :locality, :region, :postal_code].each do |attribute|
        whitehouse.send("#{attribute}=", nil)
      end
      assert_difference 'Geocoding.count', -1 do
        whitehouse.save!
      end
      whitehouse.reload
      whitehouse.geocoding.should be_nil
    end
  end

  describe "on save" do
    it "should not create geocode without changes" do
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
  
  describe "on save with an existing geocode" do
    before do
      @location = vacations(:saugatuck)
      @location.attributes = {:locality => 'Beverly Hills', :postal_code => '90210'}
    end
    
    it "should destroy the old geocoding" do
      assert_no_difference('Geocoding.count') { @location.save! }
    end

    it "should set the new geocode" do
      @location.save!
      @location.geocode.should == geocodes(:beverly_hills)
    end
    
  end
  
  describe "validates_as_geocodable" do
    before do
      @model = Class.new(Vacation)
      @vacation = @model.new :locality => "Grand Rapids", :region => "MI"
    end

    it "should be valid with geocodable address" do
      @model.validates_as_geocodable
      assert @vacation.valid?
    end

    it "should be invalid without geocodable address" do
      @model.validates_as_geocodable
      Geocode.geocoder.expects(:locate).raises(Graticule::Error)
      assert !@vacation.valid?
      assert_equal 1, @vacation.errors.size
      assert_equal "Address could not be geocoded.", @vacation.errors[:base]
    end
    
    it "should be valid with the same precision" do
      @model.validates_as_geocodable :precision => :street
      Geocode.geocoder.expects(:locate).returns(Graticule::Location.new(:precision => 'street'))
      assert @vacation.valid?
    end
    
    it "should be valid with a higher precision" do
      @model.validates_as_geocodable :precision => :region
      Geocode.geocoder.expects(:locate).returns(Graticule::Location.new(:precision => 'street'))
      assert @vacation.valid?
    end
    
    it "should be invalid with a lower precision" do
      @model.validates_as_geocodable :precision => :street
      Geocode.geocoder.expects(:locate).returns(Graticule::Location.new(:precision => 'region'))
      assert !@vacation.valid?
      assert_equal "Address could not be geocoded.", @vacation.errors[:base]
    end

    it "should allow nil" do
      @model.validates_as_geocodable :allow_nil => true
      assert @model.new.valid?
    end
    
    it "should be invalid if block returns false" do
      @model.validates_as_geocodable(:allow_nil => false) do |geocode|
        ["USA", "US"].include?(geocode.country)
      end
      Geocode.geocoder.expects(:locate).returns(Graticule::Location.new(:country => 'CA'))
      assert !@vacation.valid?
    end

    it "should be valid if block returns true" do
      @model.validates_as_geocodable(:allow_nil => false) do |geocode|
        ["USA", "US"].include?(geocode.country)
      end
      Geocode.geocoder.expects(:locate).returns(Graticule::Location.new(:country => 'US'))
      
      assert @vacation.valid?
    end
  end
  
  describe "find with origin" do
    it "should add distance to result" do
      Vacation.find(1, :origin => "49406").distance.to_f.should be_close(0.794248231790402, 0.2)
    end
  end
  
  describe "find within" do
    before do
      @results = Vacation.find(:all, :origin => 49406, :within => 10)
    end
    
    it "should find locations within radius" do
      @results.should include(vacations(:saugatuck))
    end
    
    it "should add distance to results" do
      @results.first.distance.to_f.should be_close(0.794248231790402, 0.2)
    end
    
    it "should find within" do
      spots = Vacation.find(:all, :origin => "49406", :within => 3)
      assert_equal 1, spots.size
      assert_equal vacations(:saugatuck), spots.first
    end

    it "should count within" do
      spots_count = Vacation.count(:origin => "49406", :within => 3)
      assert_equal 1, spots_count
    end

    it "should be able to find within kilometers" do
      saugatuck = Vacation.find(:first, :within => 2, :units => :kilometers, :origin => "49406")
      assert_equal vacations(:saugatuck), saugatuck
      assert_in_delta 1.27821863, saugatuck.distance, 0.2
    end
    
  end
  
  describe "distance_to" do
    before do
      @saugatuck = vacations(:saugatuck)
      @douglas = Vacation.create!(:name => 'Douglas', :postal_code => '49406')
    end

    it 'should calculate distance from a string' do
      @douglas.distance_to(geocodes(:saugatuck_geocode).query).should be_close(0.794248231790402, 0.2)
    end
    it 'should calculate distance from a geocode' do
      @douglas.distance_to(geocodes(:saugatuck_geocode)).should be_close(0.794248231790402, 0.2)
    end

    it 'should calculate distance from a geocodable model' do
      @douglas.distance_to(@saugatuck).should be_close(0.794248231790402, 0.2)
      @saugatuck.distance_to(@douglas).should be_close(0.794248231790402, 0.2)
    end

    it 'should calculate distance in default miles' do
      @douglas.distance_to(@saugatuck, :units => :miles).should be_close(0.794248231790402, 0.2)
    end
    
    it 'should calculate distance in default kilometers' do
      @douglas.distance_to(@saugatuck, :units => :kilometers).should be_close(1.27821863, 0.2)
    end
    
    it 'should return nil with invalid geocode' do
      @douglas.distance_to(Geocode.new).should be_nil
      @douglas.distance_to(nil).should be_nil
    end
    
  end
  
  it "should have beyond" do
    spots = Vacation.find(:all, :origin => "49406", :beyond => 3)
    spots.size.should == 1
    spots.first.should == vacations(:whitehouse)
  end

  it "should have count for beyond" do
    count = Vacation.count(:origin => "49406", :beyond => 3)
    count.should == 1
  end

  it "should find beyond with other units" do
    whitehouse = Vacation.find(:first, :beyond => 3, :units => :kilometers, :origin => "49406")
    assert_equal vacations(:whitehouse), whitehouse
    assert_in_delta 877.554975851074, whitehouse.distance, 1
  end
  
  it "should find nearest" do
    assert_equal vacations(:saugatuck), Vacation.find(:nearest, :origin => "49406")
  end
  
  it "should find farthest" do
    assert_equal vacations(:whitehouse), Vacation.find(:farthest, :origin => "49406")
  end
  
  it "should raise error with find nearest and including" do
    assert_raises(ArgumentError) { Vacation.find(:nearest, :origin => '49406', :include => :nearest_city) }
  end
  
  it "should use units set in declared options" do
    Vacation.acts_as_geocodable_options.merge! :units => :kilometers
    saugatuck = Vacation.find(:first, :within => 2, :units => :kilometers, :origin => "49406")
    assert_in_delta 1.27821863, saugatuck.distance, 0.2
  end
  
  it "should find with order" do
    expected = [vacations(:saugatuck), vacations(:whitehouse)]
    actual = Vacation.find(:all, :origin => '49406', :order => 'distance')
    assert_equal expected, actual
  end
  
  it "can set the geocode to nil" do
    assert_nil Vacation.send(:location_to_geocode, nil)
  end
  
  it "can convert to a geocode" do
    g = Geocode.new
    assert(g === Vacation.send(:location_to_geocode, g))
  end
  
  it "can convert a string to a geocode" do
    assert_equal geocodes(:douglas), Vacation.send(:location_to_geocode, '49406')
  end

  it "can covert a numeric zip to a geocode" do
    assert_equal geocodes(:douglas), Vacation.send(:location_to_geocode, 49406)
  end
  
  it "should convert a geocodable to a geocode" do
    assert_equal geocodes(:white_house_geocode),
      Vacation.send(:location_to_geocode, vacations(:whitehouse))
  end
  
  it "should raise an error with nearest city and bad arguments" do
    assert_raises(ArgumentError) { Vacation.find(:nearest, :include => :nearest_city, :origin => 49406) }
  end
  
  it "should run a callback after geocoding" do
    location = CallbackLocation.new :address => "Holland, MI"
    assert_nil location.geocoding
    location.expects(:done_geocoding).once.returns(true)
    assert location.save!
  end

  it "should not run callbacks after geocoding if the object is the same" do
    location = CallbackLocation.create(:address => "Holland, MI")
    assert_not_nil location.geocoding
    location.expects(:done_geocoding).never
    assert location.save!
  end
  
  
end
