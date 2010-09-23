require 'spec_helper'

describe Geocode do
  # fixtures :geocodes
  
  describe 'distance_to' do
    before do
      @washington_dc = geocodes(:white_house_geocode)
      @chicago = geocodes(:chicago_geocode)
    end

    it 'should properly calculate distance in default units' do
      @washington_dc.distance_to(@chicago).should be_close(594.820, 1.0)
    end

    it 'should properly calculate distance in default miles' do
      @washington_dc.distance_to(@chicago, :miles).should be_close(594.820, 1.0)
    end
    
    it 'should properly calculate distance in default kilometers' do
      @washington_dc.distance_to(@chicago, :kilometers).should be_close(957.275, 1.0)
    end
    
    it 'should return nil with invalid geocode' do
      @chicago.distance_to(Geocode.new).should be(nil)
      @chicago.distance_to(nil).should be(nil)
    end
  end
  
  describe 'find_or_create_by_query' do
    it 'should finds existing geocode' do
      Geocode.find_or_create_by_query('Holland, MI').should == geocodes(:holland)
    end
  end
  
  describe "find_or_create_by_location" do
    it "should find existing location" do
      location = Graticule::Location.new(:postal_code => "20502",
        :street => "1600 Pennsylvania Ave NW",
        :locality => "Washington",
        :region => "DC")
      Geocode.find_or_create_by_location(location).should == geocodes(:white_house_geocode)
    end
    
    it "should return nil when location can't be geocoded" do
      Geocode.geocoder.expects(:locate).raises(Graticule::Error)
      assert_no_difference 'Geocode.count' do 
        Geocode.find_or_create_by_location(Graticule::Location.new(:street => 'FAIL!')).should be(nil)
      end
    end
    
  end
  
  describe 'coordinates' do
    it 'should return longitude and latitude' do
      geocodes(:saugatuck_geocode).coordinates.should == "-86.200722,42.654781"
    end
  end
  
  describe 'to_s' do
    it 'should return the coordinates' do
      geocodes(:saugatuck_geocode).to_s.should == geocodes(:saugatuck_geocode).coordinates
    end
  end
  
  describe 'geocoded?' do
    it 'should be true with both a latitude and a longitude' do
      assert Geocode.new(:latitude => 1, :longitude => 1).geocoded?
    end
    
    it 'should be false when missing coordinates' do
      assert !Geocode.new.geocoded?
    end
    
    it 'should be false when missing a latitude' do
      assert !Geocode.new(:longitude => 1).geocoded?
    end

    it 'should be false when missing a longitude' do
      assert !Geocode.new(:latitude => 1).geocoded?
    end
  end
  
end
