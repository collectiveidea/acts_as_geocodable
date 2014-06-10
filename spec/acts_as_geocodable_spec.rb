require "spec_helper"

describe ActsAsGeocodable do
  before do
    @white_house = FactoryGirl.create(:whitehouse)
    @saugatuck = FactoryGirl.create(:saugatuck)
  end

  describe "geocode" do
    it "should be the geocode from the geocoding" do
      expect(@white_house.geocode).to eq(@white_house.geocoding.geocode)
    end

    it "should be nil without a geocoding" do
      expect(Vacation.new.geocode).to be_nil
    end
  end

  describe "to_location" do
    it "should return a graticule location" do
      expect(@white_house.to_location).to be_kind_of(Graticule::Location)
    end
  end

  describe "with address normalization" do
    before do
      Vacation.acts_as_geocodable_options[:normalize_address] = true

      allow(Geocode.geocoder).to receive(:locate).and_return(
        Graticule::Location.new(locality: "San Clemente", region: "CA")
      )
    end

    it "should update address fields with result" do
      vacation = Vacation.create! locality: "sanclemente", region: "ca"
      expect(vacation.locality).to eq("San Clemente")
      expect(vacation.region).to eq("CA")
    end

    it "should update address blob" do
      allow(Geocode.geocoder).to receive(:locate).and_return(
        Graticule::Location.new(locality: "Grand Rapids", region: "MI", country: "US")
      )

      vacation = AddressBlobVacation.create! address: "grand rapids, mi"
      expect(vacation.address).to eq("Grand Rapids, MI US")
    end
  end

  describe "without address normalization" do
    before do
      Vacation.acts_as_geocodable_options[:normalize_address] = false

      allow(Geocode.geocoder).to receive(:locate).and_return(
        Graticule::Location.new(locality: "Portland", region: "OR", postal_code: "97212")
      )

      @vacation = Vacation.create! locality: "portland", region: "or"
    end

    it "should not update address attributes" do
      expect(@vacation.locality).to eq("portland")
      expect(@vacation.region).to eq("or")
    end

    it "should fill in blank attributes" do
      expect(@vacation.postal_code).to eq("97212")
    end
  end

  describe "with blank location attributes" do
    it "should not create geocode" do
      expect(Geocode.geocoder).not_to receive(:locate)
      expect {
        expect(Vacation.create!(locality: "\n", region: " ").geocoding).to be_nil
      }.not_to change { Geocode.count }
    end

    it "should destroy existing geocoding" do
      [:name, :street, :locality, :region, :postal_code].each do |attribute|
        @white_house.send("#{attribute}=", nil)
      end

      expect(lambda { @white_house.save! }).to change(Geocoding, :count).by(-1)
      @white_house.reload
      expect(@white_house.geocoding).to be_nil
    end
  end

  describe "on save" do
    it "should not create geocode without changes" do
      expect(@white_house.geocoding).not_to be_nil
      original_geocode = @white_house.geocode
      expect { @white_house.save!; @white_house.reload }.not_to change { Geocode.count }
      expect(@white_house.geocode).to eq(original_geocode)
    end

    it "should not create geocoding without changes" do
      expect(@white_house.geocoding).not_to be_nil
      original_geocode = @white_house.geocode
      expect { @white_house.save!; @white_house.reload }.not_to change { Geocoding.count }
      expect(@white_house.geocode).to eq(original_geocode)
    end
  end

  describe "on save with an existing geocode" do
    before do
      @white_house.attributes = { street: "", locality: "Saugatuck", region: "MI", postal_code: "" }
    end

    it "should destroy the old geocoding, create a new one, and leave the count the same" do
      expect { @white_house.save! }.not_to change { Geocoding.count }
    end

    it "should set the new geocode" do
      @white_house.save!
      expect(@white_house.geocode.postal_code.to_s).to eq("49406")
    end
  end

  describe "validates_as_geocodable" do
    before do
      @model = Class.new(Vacation)
      @vacation = @model.new locality: "Saugatuck", region: "MI"
    end

    it "should be valid with geocodable address" do
      @model.validates_as_geocodable
      expect(@vacation).to be_valid
    end

    it "should be invalid without geocodable address" do
      @model.validates_as_geocodable
      expect(Geocode.geocoder).to receive(:locate).and_raise(Graticule::Error)
      expect(@vacation).not_to be_valid
      expect(@vacation.errors.size).to eq(1)
      expect(@vacation.errors[:base]).to include("Address could not be geocoded.")
    end

    it "should be valid with the same precision" do
      @model.validates_as_geocodable precision: :street
      expect(Geocode.geocoder).to receive(:locate).and_return(Graticule::Location.new(precision: "street"))
      expect(@vacation).to be_valid
    end

    it "should be valid with a higher precision" do
      @model.validates_as_geocodable precision: :region
      expect(Geocode.geocoder).to receive(:locate).and_return(Graticule::Location.new(precision: "street"))
      expect(@vacation).to be_valid
    end

    it "should be invalid with a lower precision" do
      @model.validates_as_geocodable precision: :street
      expect(Geocode.geocoder).to receive(:locate).and_return(Graticule::Location.new(precision: "region"))
      expect(@vacation).not_to be_valid
      expect(@vacation.errors[:base]).to include("Address could not be geocoded.")
    end

    it "should allow nil" do
      @model.validates_as_geocodable allow_nil: true
      expect(@model.new).to be_valid
    end

    it "should be invalid if validation block returns false" do
      expect(Geocode.geocoder).to receive(:locate).and_return(Graticule::Location.new(country: "CA"))
      staycation = Staycation.new locality: "Saugatuck", region: "MI"
      expect(staycation).not_to be_valid
    end

    it "should be valid if validation block returns true" do
      expect(Geocode.geocoder).to receive(:locate).and_return(Graticule::Location.new(country: "US"))
      staycation = Staycation.new locality: "Saugatuck", region: "MI"
      expect(staycation).to be_valid
    end
  end

  describe "find with origin" do
    it "should add distance to result" do
      expect(Vacation.origin("49406").first.distance).to be_present
    end
  end

  describe "find within" do
    before do
      @results = Vacation.origin(49406, within: 10).all
    end

    it "should find locations within radius" do
      expect(@results).to include(@saugatuck)
    end

    it "should add distance to results" do
      expect(@results.first.distance).to be_present
    end

    it "should find within" do
      spots = Vacation.origin("49406", within: 3).all
      expect(spots.size).to eq(1)
      expect(spots.first).to eq(@saugatuck)
    end

    it "should count within" do
      spots_count = Vacation.origin("49406", within: 3).count(:all)
      expect(spots_count).to eq(1)
    end

    it "should be able to find within kilometers" do
      saugatuck = Vacation.origin(49406, within: 2, units: :kilometers).first
      expect(saugatuck).to eq(@saugatuck)
    end
  end

  describe "distance_to" do
    before do
      @san_francisco = Vacation.create!(name: "San Francisco", locality: "San Francisco", region: "CA")
    end

    it "should calculate distance from a string" do
      expect(@san_francisco.distance_to(@saugatuck.geocode.query)).to be_within(2).of(1927)
    end

    it "should calculate distance from a geocode" do
      expect(@san_francisco.distance_to(@saugatuck.geocode)).to be_within(2).of(1927)
    end

    it "should calculate distance from a geocodable model" do
      expect(@san_francisco.distance_to(@saugatuck)).to be_within(2).of(1927)
      expect(@saugatuck.distance_to(@san_francisco)).to be_within(2).of(1927)
    end

    it "should calculate distance in default miles" do
      expect(@san_francisco.distance_to(@saugatuck, units: :miles)).to be_within(2).of(1927)
    end

    it "should calculate distance in default kilometers" do
      expect(@san_francisco.distance_to(@saugatuck, units: :kilometers)).to be_within(2).of(3101)
    end

    it "should return nil with invalid geocode" do
      expect(@san_francisco.distance_to(Geocode.new)).to be_nil
      expect(@san_francisco.distance_to(nil)).to be_nil
    end
  end

  it "should have beyond" do
    spots = Vacation.origin("49406", beyond: 3).all
    expect(spots.first).to eq(@white_house)
    expect(spots.size).to eq(1)
  end

  it "should have count for beyond" do
    count = Vacation.origin("49406", beyond: 3).count(:all)
    expect(count).to eq(1)
  end

  it "should find beyond with other units" do
    whitehouse = Vacation.origin("49406", beyond: 3, units: :kilometers).first
    expect(whitehouse).to eq(@white_house)
    expect(whitehouse.distance.to_f).to be_within(1).of(877.554975851074)
  end

  it "should find nearest" do
    expect(Vacation.origin("49406").nearest).to eq(@saugatuck)
  end

  it "should find farthest" do
    expect(Vacation.origin("49406").farthest).to eq(@white_house)
  end

  it "should raise error with find nearest and including" do
    expect(lambda { Vacation.origin("49406").nearest(include: :nearest_city) }).to raise_error(ArgumentError)
  end

  it "should find with order" do
    expected = [@saugatuck, @white_house]
    actual = Vacation.origin("49406").order("distance").all
    expect(actual).to eq(expected)
  end

  it "can set the geocode to nil" do
    expect(Vacation.send(:location_to_geocode, nil)).to be_nil
  end

  it "can convert to a geocode" do
    g = Geocode.new
    expect(Vacation.send(:location_to_geocode, g)).to eql(g)
  end

  it "can convert a string to a geocode" do
    douglas_geocode = FactoryGirl.create(:douglas_geocode)
    expect(Vacation.send(:location_to_geocode, "49406")).to eq(douglas_geocode)
  end

  it "can covert a numeric zip to a geocode" do
    douglas_geocode = FactoryGirl.create(:douglas_geocode)
    expect(Vacation.send(:location_to_geocode, 49406)).to eq(douglas_geocode)
  end

  it "should convert a geocodable to a geocode" do
    expect(Vacation.send(:location_to_geocode, @white_house)).to eq(@white_house.geocode)
  end

  describe "callbacks" do
    it "should run a callback after geocoding" do
      location = CallbackLocation.new address: "San Francisco"
      expect(location.geocoding).to be_nil
      expect(location).to receive(:done_geocoding).once.and_return(true)
      expect(location.save!).to be_truthy
    end

    it "should not run callbacks after geocoding if the object is the same" do
      location = CallbackLocation.create(address: "San Francisco")
      expect(location.geocoding).not_to be_nil
      expect(location).not_to receive(:done_geocoding)
      expect(location.save!).to be_truthy
    end
  end
end
