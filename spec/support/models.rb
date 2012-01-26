class Vacation < ActiveRecord::Base
  acts_as_geocodable :normalize_address => true
  belongs_to :nearest_city, :class_name => 'City', :foreign_key => 'city_id'
end

class Staycation < ActiveRecord::Base
  self.table_name = 'vacations'

  acts_as_geocodable
  validates_as_geocodable(:allow_nil => false) do |geocode|
    ["USA", "US"].include?(geocode.country)
  end
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
  set_callback :geocoding, :after, :done_geocoding

  def done_geocoding
    true
  end
end