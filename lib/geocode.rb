class Geocode < ActiveRecord::Base
  #
  # Thanks to Chris Veness for distance formulas.
  #   * http://www.movable-type.co.uk/scripts/LatLong.html
  #   * http://www.movable-type.co.uk/scripts/LatLongVincenty.html
  #
  
  include Comparable
  include Math
  
  has_many :geocodings
  
  validates_uniqueness_of :query
  before_save :geocode
  
  cattr_accessor :geocoder
  
  def self.geocode location
    result = geocoder.locate(location)
    
    # Yahoo Geocoder returns and array of possibilities.  We take the first one.
    if result.is_a? Array
      result = result.first
    end
    
    # Beautify some strings
    result.street = result.street.titleize if result.street
    result.city = result.city.titleize if result.city

    result
  rescue
    # Geocoder threw exception
    return nil
  end
  
  def self.earth_radius(units=:miles)
    if units == :kilometers
      6378.135
    else
      3963.1676
    end
  end
  
  def self.earth_major_axis_radius(units=:miles)
    # WGS-84 numbers
    if units == :kilometers
      6378.137
    else
      3963.19059
    end
  end
  
  def self.earth_minor_axis_radius(units=:miles)
    # WGS-84 numbers
    if units == :kilometers
      6356.7523142
    else
      3949.90276
    end
  end
  
  def self.distance(first, second, units=:miles)
    return false unless first && first.geocoded? && second && second.geocoded?
  
    # TODO: Does anyone have an equation that is either faster or more accurate?
    first_longitude = self.deg2rad(first.longitude)
    first_latitude = self.deg2rad(first.latitude)
    second_longitude = self.deg2rad(second.longitude)
    second_latitude = self.deg2rad(second.latitude)
        
    Math.acos(
        Math.cos(first_longitude) *
        Math.cos(second_longitude) * 
        Math.cos(first_latitude) * 
        Math.cos(second_latitude) +
         
        Math.cos(first_latitude) *
        Math.sin(first_longitude) *
        Math.cos(second_latitude) *
        Math.sin(second_longitude) +
        
        Math.sin(first_latitude) *
        Math.sin(second_latitude)
    ) * self.earth_radius(units)
  end
  
  #
  # Distance Measured usign the Spherical Law of Cosines
  # Simplist though least accurate (earth isn't a perfect sphere)
  # d = acos(sin(lat1).sin(lat2)+cos(lat1).cos(lat2).cos(long2−long1)).R
  #
  def self.distance_using_spherical_law_of_cosines(first, second, units=:miles)
    first_longitude   = deg2rad(first.longitude)
    first_latitude    = deg2rad(first.latitude)
    second_longitude  = deg2rad(second.longitude)
    second_latitude   = deg2rad(second.latitude)
    
    
    Math.acos(
        Math.sin(first_latitude) *
        Math.sin(second_latitude) +
        
        Math.cos(first_latitude) * 
        Math.cos(second_latitude) *
        Math.cos(second_longitude - first_longitude)
    ) * self.earth_radius(units)
  end
  
  #
  # Distance Measured usign the Haversine Formula
  # Works better at small distances than the Spherical Law of Cosines
  # R = earth’s radius (mean radius = 6,371km)
  # Δlat = lat2− lat1
  # Δlong = long2− long1
  # a = sin²(Δlat/2) + cos(lat1).cos(lat2).sin²(Δlong/2)
  # c = 2.atan2(√a, √(1−a))
  # d = R.c
  #
  def self.distance_using_haversine_formula(first, second, units=:miles)
    first_longitude   = deg2rad(first.longitude)
    first_latitude    = deg2rad(first.latitude)
    second_longitude  = deg2rad(second.longitude)
    second_latitude   = deg2rad(second.latitude)
    
    latitude_delta  = second_latitude - first_latitude
    longitude_delta = second_longitude - first_longitude
    
    a = Math.sin(latitude_delta/2)**2 + 
        Math.cos(first_latitude) * 
        Math.cos(second_latitude) * 
        Math.sin(longitude_delta/2)**2
    
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
    
    d = earth_radius(units) * c
  end
  
  #
  # Distance Measured usign the Vincenty Formula
  # Very accurate, using an accurate ellipsoidal model of the earth
  # a, b = major & minor semiaxes of the ellipsoid	 
  # f = flattening (a−b)/a	 
  # φ1, φ2 = geodetic latitude	 
  # L = difference in longitude	 
  # U1 = atan((1−f).tanφ1) (U is ‘reduced latitude’)	 
  # U2 = atan((1−f).tanφ2)	 
  # λ = L, λ′ = 2π	 
  # while abs(λ−λ′) > 10-12 { (i.e. 0.06mm)	 
  #     	sinσ = √[ (cosU2.sinλ)² + (cosU1.sinU2 − sinU1.cosU2.cosλ)² ]	(14)
  #  	cosσ = sinU1.sinU2 + cosU1.cosU2.cosλ	(15)
  #  	σ = atan2(sinσ, cosσ)	(16)
  #  	sinα = cosU1.cosU2.sinλ / sinσ	(17)
  #  	cos²α = 1 − sin²α (trig identity; §6)	 
  #  	cos2σm = cosσ − 2.sinU1.sinU2/cos²α	(18)
  #  	C = f/16.cos²α.[4+f.(4−3.cos²α)]	(10)
  #  	λ′ = λ	 
  #  	λ = L + (1−C).f.sinα.{σ+C.sinσ.[cos2σm+C.cosσ.(−1+2.cos²2σm)]}	(11)
  # }	 	 
  # u² = cos²α.(a²−b²)/b²	 
  # A = 1+u²/16384.{4096+u².[−768+u².(320−175.u²)]}	(3)
  # B = u²/1024.{256+u².[−128+u².(74−47.u²)]}	(4)
  # Δσ = B.sinσ.{cos2σm+B/4.[cosσ.(−1+2.cos²2σm) − B/6.cos2σm.(−3+4.sin²σ).(−3+4.cos²2σm)]}	(6)
  # s = b.A.(σ−Δσ)	(19)
  # α1 = atan2(cosU2.sinλ, cosU1.sinU2 − sinU1.cosU2.cosλ)	(20)
  # α2 = atan2(cosU1.sinλ, −sinU1.cosU2 + cosU1.sinU2.cosλ)	(21)
  # Where:
  # 
  # s is the distance (in the same units as a & b)
  # α1 is the initial bearing, or forward azimuth
  # α2 is the final bearing (in direction p1→p2)
  #
  def self.distance_using_vincenty_formula(first, second, units=:miles)
    first_longitude   = deg2rad(first.longitude)
    first_latitude    = deg2rad(first.latitude)
    second_longitude  = deg2rad(second.longitude)
    second_latitude   = deg2rad(second.latitude)
    
    f = (earth_major_axis_radius - earth_minor_axis_radius) / earth_major_axis_radius
    
   l = second_longitude - first_longitude
   u1 = Math.atan((1-f) * Math.tan(first_latitude))
   u2 = Math.atan((1-f) * Math.tan(second_latitude))
   sinU1 = Math.sin(u1)
   cosU1 = Math.cos(u1)
   sinU2 = Math.sin(u2)
   cosU2 = Math.cos(u2)
    
   lambda = l
   lambdaP = 2*Math::PI
     iterLimit = 20;
     while (lambda-lambdaP).abs > 1e-12 && --iterLimit>0
       sinLambda = Math.sin(lambda)
       cosLambda = Math.cos(lambda)
       sinSigma = Math.sqrt((cosU2*sinLambda) * (cosU2*sinLambda) + 
         (cosU1*sinU2-sinU1*cosU2*cosLambda) * (cosU1*sinU2-sinU1*cosU2*cosLambda))
       return 0 if sinSigma==0  # co-incident points
       cosSigma = sinU1*sinU2 + cosU1*cosU2*cosLambda
       sigma = Math.atan2(sinSigma, cosSigma)
       sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma
       cosSqAlpha = 1 - sinAlpha*sinAlpha
       cos2SigmaM = cosSigma - 2*sinU1*sinU2/cosSqAlpha
       
       cos2SigmaM = 0 if cos2SigmaM.nan?  # equatorial line: cosSqAlpha=0 (§6)
       
       c = f/16*cosSqAlpha*(4+f*(4-3*cosSqAlpha))
       lambdaP = lambda
       lambda = l + (1-c) * f * sinAlpha *
         (sigma + c*sinSigma*(cos2SigmaM+c*cosSigma*(-1+2*cos2SigmaM*cos2SigmaM)))
     end
     return NaN if (iterLimit==0)  # formula failed to converge

     uSq = cosSqAlpha * (earth_major_axis_radius**2 - earth_minor_axis_radius**2) / (earth_minor_axis_radius**2);
     bigA = 1 + uSq/16384*(4096+uSq*(-768+uSq*(320-175*uSq)));
     bigB = uSq/1024 * (256+uSq*(-128+uSq*(74-47*uSq)));
     deltaSigma = bigB*sinSigma*(cos2SigmaM+bigB/4*(cosSigma*(-1+2*cos2SigmaM*cos2SigmaM)-
       bigB/6*cos2SigmaM*(-3+4*sinSigma*sinSigma)*(-3+4*cos2SigmaM*cos2SigmaM)));
     s = earth_minor_axis_radius*bigA*(sigma-deltaSigma);

     #s = s.toFixed(3) # round to 1mm precision
     return s
  end
  
  def geocoded?
    !latitude.blank? && !longitude.blank?
  end
  
  def self.deg2rad(deg)
  	(deg * Math::PI / 180)
  end

  def self.rad2deg(rad)
  	(rad * 180 / Math::PI)
  end
  
  # Set the latitude and longitude.
  def geocode    
    geocoded_location = Geocode.geocode query

    unless geocoded_location.nil?     
      self.latitude  = geocoded_location.latitude
      self.longitude = geocoded_location.longitude
      
      self.street = geocoded_location.street if geocoded_location.street
      self.city = geocoded_location.city if geocoded_location.city
      self.region = geocoded_location.state if geocoded_location.state
      self.postal_code = geocoded_location.zip if geocoded_location.zip
      self.country = geocoded_location.country if geocoded_location.country
    else
      # Halt callback
      false
    end
  end
 
  def geocoded
    @geocoded ||= geocodings.collect { |geocoding| geocoding.geocodable }
  end
  
  def on(geocodable)
    geocodings.create :geocodable => geocodable
  end
  
  def <=>(comparison_object)
    self.to_s <=> comparison_object.to_s
  end
  
  def coordinates
    "#{longitude},#{latitude}"
  end

  def to_s
    coordinates
  end
end