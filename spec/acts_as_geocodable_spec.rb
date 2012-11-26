require 'spec_helper'

describe ActsAsGeocodable do
  before do
    @white_house = FactoryGirl.create(:whitehouse)
    @saugatuck = FactoryGirl.create(:saugatuck)
  end
  
  describe "geocode" do
    it "should be the geocode from the geocoding" do
      @white_house.geocode.should == @white_house.geocoding.geocode
    end
    
    it "should be nil without a geocoding" do
      Vacation.new.geocode.should be_nil
    end
    
  end
  
  describe "to_location" do
    it "should return a graticule location" do
      @white_house.to_location.should be_kind_of(Graticule::Location)
    end
  end
  
  describe "with address normalization" do
    before do
      Vacation.acts_as_geocodable_options[:normalize_address] = true
      
      Geocode.geocoder.stub(:locate).and_return(
        Graticule::Location.new(:locality => "San Clemente", :region => "CA")
      )
    end

    it "should update address fields with result" do
      vacation = Vacation.create! :locality => 'sanclemente', :region => 'ca'
      vacation.locality.should == 'San Clemente'
      vacation.region.should == 'CA'
    end
    
    it "should update address blob" do
      Geocode.geocoder.stub(:locate).and_return(
        Graticule::Location.new(:locality => "Grand Rapids", :region => "MI", :country => "US")
      )

      vacation = AddressBlobVacation.create! :address => "grand rapids, mi"
      vacation.address.should == "Grand Rapids, MI US"
    end
    
  end
  
  describe "without address normalization" do
    before do
      Vacation.acts_as_geocodable_options[:normalize_address] = false
      
      Geocode.geocoder.stub(:locate).and_return(
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
      Geocode.geocoder.should_not_receive(:locate)
      lambda {
        Vacation.create!(:locality => "\n", :region => " ").geocoding.should be_nil
      }.should_not change(Geocode, :count)
    end

    it "should destroy existing geocoding" do
      [:name, :street, :locality, :region, :postal_code].each do |attribute|
        @white_house.send("#{attribute}=", nil)
      end
      
      lambda { @white_house.save! }.should change(Geocoding, :count).by(-1)
      @white_house.reload
      @white_house.geocoding.should be_nil
    end
  end

  describe "on save" do
    it "should not create geocode without changes" do
      @white_house.geocoding.should_not be_nil
      original_geocode = @white_house.geocode
      lambda { @white_house.save!; @white_house.reload }.should_not change(Geocode, :count)
      @white_house.geocode.should == original_geocode
    end
    
    it "should not create geocoding without changes" do
      @white_house.geocoding.should_not be_nil
      original_geocode = @white_house.geocode
      lambda { @white_house.save!; @white_house.reload }.should_not change(Geocoding, :count)
      @white_house.geocode.should == original_geocode
    end
    
  end
  
  describe "on save with an existing geocode" do
    before do
      @white_house.attributes = {:street => '', :locality => 'Saugatuck', :region => 'MI', :postal_code => ''}
    end
    
    it "should destroy the old geocoding, create a new one, and leave the count the same" do
      lambda { @white_house.save! }.should_not change(Geocoding, :count) 
    end

    it "should set the new geocode" do
      @white_house.save!
      @white_house.geocode.postal_code.to_s.should == '49406'
    end
    
  end
  
  describe "validates_as_geocodable" do
    before do
      @model = Class.new(Vacation)
      @vacation = @model.new :locality => "Saugatuck", :region => "MI"
    end

    it "should be valid with geocodable address" do
      @model.validates_as_geocodable
      @vacation.should be_valid
    end

    it "should be invalid without geocodable address" do
      @model.validates_as_geocodable
      Geocode.geocoder.should_receive(:locate).and_raise(Graticule::Error)
      @vacation.should_not be_valid
      @vacation.errors.size.should == 1
      @vacation.errors[:base].should include("Address could not be geocoded.")
    end
    
    it "should be valid with the same precision" do
      @model.validates_as_geocodable :precision => :street
      Geocode.geocoder.should_receive(:locate).and_return(Graticule::Location.new(:precision => 'street'))
      @vacation.should be_valid
    end
    
    it "should be valid with a higher precision" do
      @model.validates_as_geocodable :precision => :region
      Geocode.geocoder.should_receive(:locate).and_return(Graticule::Location.new(:precision => 'street'))
      @vacation.should be_valid
    end
    
    it "should be invalid with a lower precision" do
      @model.validates_as_geocodable :precision => :street
      Geocode.geocoder.should_receive(:locate).and_return(Graticule::Location.new(:precision => 'region'))
      @vacation.should_not be_valid
      @vacation.errors[:base].should include("Address could not be geocoded.")
    end

    it "should allow nil" do
      @model.validates_as_geocodable :allow_nil => true
      @model.new.should be_valid
    end
    
    it "should be invalid if validation block returns false" do
      Geocode.geocoder.should_receive(:locate).and_return(Graticule::Location.new(:country => 'CA'))
      staycation = Staycation.new :locality => "Saugatuck", :region => "MI"
      staycation.should_not be_valid
    end

    it "should be valid if validation block returns true" do
      Geocode.geocoder.should_receive(:locate).and_return(Graticule::Location.new(:country => 'US'))
      staycation = Staycation.new :locality => "Saugatuck", :region => "MI"
      staycation.should be_valid
    end
  end
  
  describe "find with origin" do
    it "should add distance to result" do
      Vacation.origin("49406").first.distance.should be_present
    end
  end
  
  describe "find within" do
    before do
      @results = Vacation.origin(49406, :within => 10).all
    end
    
    it "should find locations within radius" do
      @results.should include(@saugatuck)
    end
    
    it "should add distance to results" do
      @results.first.distance.should be_present
    end
    
    it "should find within" do
      spots = Vacation.origin("49406", :within => 3).all
      spots.size.should == 1
      spots.first.should == @saugatuck
    end

    it "should count within" do
      spots_count = Vacation.origin("49406", :within => 3).count
      spots_count.should == 1
    end

    it "should be able to find within kilometers" do
      saugatuck = Vacation.origin(49406, :within => 2, :units => :kilometers).first
      saugatuck.should == @saugatuck
    end
    
  end
  
  describe "distance_to" do
    before do
      @san_francisco = Vacation.create!(:name => 'San Francisco', :locality => 'San Francisco', :region => 'CA')
    end

    it 'should calculate distance from a string' do
      @san_francisco.distance_to(@saugatuck.geocode.query).should be_within(2).of(1927)
    end
    it 'should calculate distance from a geocode' do
      @san_francisco.distance_to(@saugatuck.geocode).should be_within(2).of(1927)
    end

    it 'should calculate distance from a geocodable model' do
      @san_francisco.distance_to(@saugatuck).should be_within(2).of(1927)
      @saugatuck.distance_to(@san_francisco).should be_within(2).of(1927)
    end

    it 'should calculate distance in default miles' do
      @san_francisco.distance_to(@saugatuck, :units => :miles).should be_within(2).of(1927)
    end
    
    it 'should calculate distance in default kilometers' do
      @san_francisco.distance_to(@saugatuck, :units => :kilometers).should be_within(2).of(3101)
    end
    
    it 'should return nil with invalid geocode' do
      @san_francisco.distance_to(Geocode.new).should be_nil
      @san_francisco.distance_to(nil).should be_nil
    end
    
  end
  
  it "should have beyond" do
    spots = Vacation.origin('49406', :beyond => 3).all
    spots.first.should == @white_house
    spots.size.should == 1
  end

  it "should have count for beyond" do
    count = Vacation.origin('49406', :beyond => 3).count
    count.should == 1
  end

  it "should find beyond with other units" do
    whitehouse = Vacation.origin('49406', :beyond => 3, :units => :kilometers).first
    whitehouse.should == @white_house
    whitehouse.distance.to_f.should be_within(1).of(877.554975851074)
  end
  
  it "should find nearest" do
    Vacation.origin("49406").nearest.should == @saugatuck
  end
  
  it "should find farthest" do
    Vacation.origin("49406").farthest.should == @white_house
  end
  
  it "should raise error with find nearest and including" do
    lambda { Vacation.origin("49406").nearest(:include => :nearest_city) }.should raise_error(ArgumentError)
  end
  
  it "should find with order" do
    expected = [@saugatuck, @white_house]
    actual = Vacation.origin('49406').order('distance').all
    actual.should == expected
  end
  
  it "can set the geocode to nil" do
    Vacation.send(:location_to_geocode, nil).should be_nil
  end
  
  it "can convert to a geocode" do
    g = Geocode.new
    Vacation.send(:location_to_geocode, g).should === g
  end
  
  it "can convert a string to a geocode" do
    douglas_geocode = FactoryGirl.create(:douglas_geocode)
    Vacation.send(:location_to_geocode, '49406').should == douglas_geocode
  end

  it "can covert a numeric zip to a geocode" do
    douglas_geocode = FactoryGirl.create(:douglas_geocode)
    Vacation.send(:location_to_geocode, 49406).should == douglas_geocode
  end
  
  it "should convert a geocodable to a geocode" do
    Vacation.send(:location_to_geocode, @white_house).should == @white_house.geocode
  end
  
  describe "callbacks" do
    it "should run a callback after geocoding" do
      location = CallbackLocation.new :address => "San Francisco"
      location.geocoding.should be_nil
      location.should_receive(:done_geocoding).once.and_return(true)
      location.save!.should be_true
    end

    it "should not run callbacks after geocoding if the object is the same" do
      location = CallbackLocation.create(:address => "San Francisco")
      location.geocoding.should_not be_nil
      location.should_not_receive(:done_geocoding)
      location.save!.should be_true
    end
  end
  
end
