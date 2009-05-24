require File.join(File.dirname(__FILE__), 'test_helper')

class GeocodeTest < ActiveSupport::TestCase
  fixtures :geocodes
  
  context 'distance_to' do
    setup do
      @washington_dc = geocodes(:white_house_geocode)
      @chicago = geocodes(:chicago_geocode)
    end

    should 'properly calculate distance in default units' do
      @washington_dc.distance_to(@chicago).should be_close(594.820, 1.0)
    end

    should 'properly calculate distance in default miles' do
      @washington_dc.distance_to(@chicago, :miles).should be_close(594.820, 1.0)
    end
    
    should 'properly calculate distance in default kilometers' do
      @washington_dc.distance_to(@chicago, :kilometers).should be_close(957.275, 1.0)
    end
    
    should 'return nil with invalid geocode' do
      @chicago.distance_to(Geocode.new).should be(nil)
      @chicago.distance_to(nil).should be(nil)
    end
  end
  
  context 'find_or_create_by_query' do
    should 'finds existing geocode' do
      Geocode.find_or_create_by_query('Holland, MI').should == geocodes(:holland)
    end
  end
  
  context "find_or_create_by_location" do
    should "find existing location" do
      location = Graticule::Location.new(:postal_code => "20502",
        :street => "1600 Pennsylvania Ave NW",
        :locality => "Washington",
        :region => "DC")
      Geocode.find_or_create_by_location(location).should == geocodes(:white_house_geocode)
    end
    
    should "return nil when location can't be geocoded" do
      Geocode.geocoder.expects(:locate).raises(Graticule::Error)
      assert_no_difference 'Geocode.count' do 
        Geocode.find_or_create_by_location(Graticule::Location.new(:street => 'FAIL!')).should be(nil)
      end
    end
    
  end
  
  context 'coordinates' do
    should 'return longitude and latitude' do
      geocodes(:saugatuck_geocode).coordinates.should == "-86.200722,42.654781"
    end
  end
  
  context 'to_s' do
    should 'return the coordinates' do
      geocodes(:saugatuck_geocode).to_s.should == geocodes(:saugatuck_geocode).coordinates
    end
  end
  
  context 'geocoded?' do
    should 'be true with both a latitude and a longitude' do
      assert Geocode.new(:latitude => 1, :longitude => 1).geocoded?
    end
    
    should 'be false when missing coordinates' do
      assert !Geocode.new.geocoded?
    end
    
    should 'be false when missing a latitude' do
      assert !Geocode.new(:longitude => 1).geocoded?
    end

    should 'be false when missing a longitude' do
      assert !Geocode.new(:latitude => 1).geocoded?
    end
  end
  
end

__END__



def test_to_location
  location = geocodes(:white_house_geocode).to_location

  assert_kind_of Graticule::Location, location
  [:street, :locality, :region, :postal_code, :latitude, :longitude].each do |attr|
    assert_not_nil location.send(attr)
  end
end
