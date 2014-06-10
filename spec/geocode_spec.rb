require "spec_helper"

describe Geocode do
  describe "distance_to" do
    before do
      @washington_dc = FactoryGirl.create(:white_house_geocode)
      @chicago = FactoryGirl.create(:chicago_geocode)
    end

    it "should properly calculate distance in default units" do
      expect(@washington_dc.distance_to(@chicago)).to be_within(1.0).of(594.820)
    end

    it "should properly calculate distance in default miles" do
      expect(@washington_dc.distance_to(@chicago, :miles)).to be_within(1.0).of(594.820)
    end

    it "should properly calculate distance in default kilometers" do
      expect(@washington_dc.distance_to(@chicago, :kilometers)).to be_within(1.0).of(957.275)
    end

    it "should return nil with invalid geocode" do
      expect(@chicago.distance_to(Geocode.new)).to be_nil
      expect(@chicago.distance_to(nil)).to be_nil
    end
  end

  describe "find_or_create_by_query" do
    it "should finds existing geocode" do
      existing = FactoryGirl.create(:holland_geocode)
      expect(Geocode.find_or_create_by_query("Holland, MI")).to eq(existing)
    end
  end

  describe "find_or_create_by_location" do
    it "should find existing location" do
      existing = FactoryGirl.create(:white_house_geocode)
      location = Graticule::Location.new(postal_code: "20502",
        street: "1600 Pennsylvania Ave NW",
        locality: "Washington",
        region: "DC")
      expect(Geocode.find_or_create_by_location(location)).to eq(existing)
    end

    it "should return nil when location can't be geocoded" do
      expect(Geocode.geocoder).to receive(:locate).and_raise(Graticule::Error)
      expect {
        expect(Geocode.find_or_create_by_location(Graticule::Location.new(street: "FAIL!"))).to be_nil
      }.not_to change { Geocode.count }
    end

  end

  describe "coordinates" do
    it "should return longitude and latitude" do
      geocode = FactoryGirl.create(:saugatuck_geocode)
      expect(geocode.coordinates).to eq("-86.200722,42.654781")
    end
  end

  describe "to_s" do
    it "should return the coordinates" do
      geocode = FactoryGirl.create(:saugatuck_geocode)
      expect(geocode.to_s).to eq(geocode.coordinates)
    end
  end

  describe "geocoded?" do
    it "should be true with both a latitude and a longitude" do
      expect(Geocode.new(latitude: 1, longitude: 1)).to be_geocoded
    end

    it "should be false when missing coordinates" do
      expect(Geocode.new).not_to be_geocoded
    end

    it "should be false when missing a latitude" do
      expect(Geocode.new(latitude: 1)).not_to be_geocoded
    end

    it "should be false when missing a longitude" do
      expect(Geocode.new(latitude: 1)).not_to be_geocoded
    end
  end

end
