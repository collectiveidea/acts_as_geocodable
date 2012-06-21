require 'spec_helper'

describe Geocode do
  # fixtures :geocodes
  
  describe 'distance_to' do
    before do
      @washington_dc = FactoryGirl.create(:white_house_geocode)
      @chicago = FactoryGirl.create(:chicago_geocode)
    end

    it 'should properly calculate distance in default units' do
      @washington_dc.distance_to(@chicago).should be_within(1.0).of(594.820)
    end

    it 'should properly calculate distance in default miles' do
      @washington_dc.distance_to(@chicago, :miles).should be_within(1.0).of(594.820)
    end
    
    it 'should properly calculate distance in default kilometers' do
      @washington_dc.distance_to(@chicago, :kilometers).should be_within(1.0).of(957.275)
    end
    
    it 'should return nil with invalid geocode' do
      @chicago.distance_to(Geocode.new).should be_nil
      @chicago.distance_to(nil).should be_nil
    end
  end
  
  describe 'find_or_create_by_query' do
    it 'should finds existing geocode' do
      existing = FactoryGirl.create(:holland_geocode)
      Geocode.find_or_create_by_query('Holland, MI').should == existing
    end
  end
  
  describe "find_or_create_by_location" do
    it "should find existing location" do
      existing = FactoryGirl.create(:white_house_geocode)
      location = Graticule::Location.new(:postal_code => "20502",
        :street => "1600 Pennsylvania Ave NW",
        :locality => "Washington",
        :region => "DC")
      Geocode.find_or_create_by_location(location).should == existing
    end
    
    it "should return nil when location can't be geocoded" do
      Geocode.geocoder.should_receive(:locate).and_raise(Graticule::Error)
      lambda { 
        Geocode.find_or_create_by_location(Graticule::Location.new(:street => 'FAIL!')).should be_nil
      }.should_not change(Geocode, :count)
    end
    
  end
  
  describe 'coordinates' do
    it 'should return longitude and latitude' do
      geocode = FactoryGirl.create(:saugatuck_geocode)
      geocode.coordinates.should == "-86.200722,42.654781"
    end
  end
  
  describe 'to_s' do
    it 'should return the coordinates' do
      geocode = FactoryGirl.create(:saugatuck_geocode)
      geocode.to_s.should == geocode.coordinates
    end
  end
  
  describe 'geocoded?' do
    it 'should be true with both a latitude and a longitude' do
      Geocode.new(:latitude => 1, :longitude => 1).should be_geocoded
    end
    
    it 'should be false when missing coordinates' do
      Geocode.new.should_not be_geocoded
    end
    
    it 'should be false when missing a latitude' do
      Geocode.new(:latitude => 1).should_not be_geocoded
    end

    it 'should be false when missing a longitude' do
      Geocode.new(:latitude => 1).should_not be_geocoded
    end
  end
  
end
