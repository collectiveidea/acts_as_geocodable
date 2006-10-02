require File.join(File.dirname(__FILE__), 'test_helper')


class Vacation < ActiveRecord::Base
  acts_as_geocodable :normalize_address => true
end

class City < ActiveRecord::Base
  acts_as_geocodable
end

class ActsAsGeocodableTest < Test::Unit::TestCase
  # Replace this with your real tests.
  def test_this_plugin
    flunk
  end
end
