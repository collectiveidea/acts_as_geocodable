class Geocoding < ActiveRecord::Base
  belongs_to :geocode
  belongs_to :geocodable, :polymorphic => true

  def self.geocoded_class(geocodable)
    ActiveRecord::Base.send(:class_name_of_active_record_descendant, geocodable.class).to_s
  end
  
  def self.find_geocodable(geocoded_class, geocoded_id)
    geocoded_class.constantize.find(geocoded_id)
  end
end