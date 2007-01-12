module CollectiveIdea
  module Acts #:nodoc:
    module Geocodable #:nodoc:
      
      def self.included(mod)
        mod.extend(ClassMethods)
      end

      # declare the class level helper methods which
      # will load the relevant instance methods
      # defined below when invoked
      module ClassMethods
        
        def acts_as_geocodable(options = {})
          options = {
            :address => {:street => :street, :city => :city, :region => :region, :postal_code => :postal_code, :country => :country},
            :normalize_address => false
          }.merge(options)
          
          write_inheritable_attribute :acts_as_geocodable_options, options
          class_inheritable_reader :acts_as_geocodable_options

          has_one :geocoding, :as => :geocodable, :include => :geocode, :dependent => :destroy
          
          after_save :attach_geocode          
          
          include CollectiveIdea::Acts::Geocodable::InstanceMethods
          extend CollectiveIdea::Acts::Geocodable::SingletonMethods
        end
        
      end

      module SingletonMethods
        
        def find_all_within_radius(from, radius = 50, options = {})
          units = options.delete(:units) || :miles
          with_scope(:find => { :include => {:geocoding => :geocode}, :conditions => 'geocodes.id is not null' }) do
            find(:all, options).select {|to| to.geocode && from.distance_to(to.geocode, units) <= radius}
          end
        end
        
        def find_within_radius(location, radius=50, units=:miles)
          # Ensure valid floats
          latitude, longitude = location.latitude.to_f, location.longitude.to_f, radius.to_f
          class_name = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s
          # TODO: refactor so SQL is database agnostic
          
          # with_scope :find => {
          #       :conditions => ["(#{Graticule::Distance::EARTH_RADIUS[units]} * ACOS(
          #         COS(RADIANS(`latitude`))*COS(RADIANS(`longitude`))
          #         	* COS(RADIANS(:latitude))*COS(RADIANS(:longitude))
          #         + COS(RADIANS(`latitude`))*SIN(RADIANS(`longitude`))
          #         	* COS(RADIANS(:latitude))*SIN(RADIANS(:longitude))
          #         + SIN(RADIANS(`latitude`))
          #         	* SIN(RADIANS(:latitude))
          #         ) ) <= :radius",
          #         {:latitude => latitude, :longitude => longitude, :radius => radius}],
          #       :order => "distance"
          #     } do
          #   find(:all, :select => "DISTINCT #{table_name}.*, geocodes.latitude, geocodes.longitude,
          #       (#{Graticule::Distance::EARTH_RADIUS[units]} * ACOS(
          #       COS(RADIANS(`latitude`))*COS(RADIANS(`longitude`))
          #       	* COS(RADIANS(:latitude))*COS(RADIANS(:longitude))
          #       + COS(RADIANS(`latitude`))*SIN(RADIANS(`longitude`))
          #       	* COS(RADIANS(:latitude))*SIN(RADIANS(:longitude))
          #       + SIN(RADIANS(`latitude`))
          #       	* SIN(RADIANS(:latitude))
          #       ) ) as distance")
          # end
        
          return find_by_sql(
            ["SELECT DISTINCT #{table_name}.*, geocodes.latitude, geocodes.longitude, (#{Graticule::Distance::EARTH_RADIUS[units]} * ACOS(
                                      COS(RADIANS(`latitude`))*COS(RADIANS(`longitude`))
                                      	* COS(RADIANS(:latitude))*COS(RADIANS(:longitude))
                                      + COS(RADIANS(`latitude`))*SIN(RADIANS(`longitude`))
                                      	* COS(RADIANS(:latitude))*SIN(RADIANS(:longitude))
                                      + SIN(RADIANS(`latitude`))
                                      	* SIN(RADIANS(:latitude))
                                      ) ) as distance
                                      FROM #{table_name}, geocodes, geocodings " +
            "WHERE #{table_name}.#{primary_key} = geocodings.geocodable_id " +
            "AND geocodings.geocodable_type = '#{class_name}' " +
            "AND geocodings.geocode_id = geocodes.id "+
            "AND (#{Graticule::Distance::EARTH_RADIUS[units]} * ACOS(
                                      COS(RADIANS(`latitude`))*COS(RADIANS(`longitude`))
                                      	* COS(RADIANS(:latitude))*COS(RADIANS(:longitude))
                                      + COS(RADIANS(`latitude`))*SIN(RADIANS(`longitude`))
                                      	* COS(RADIANS(:latitude))*SIN(RADIANS(:longitude))
                                      + SIN(RADIANS(`latitude`))
                                      	* SIN(RADIANS(:latitude))
                                      ) ) <= :radius " +
            "ORDER BY distance",
            {:latitude => latitude, :longitude => longitude, :radius => radius}])
        end
        
        def find_within_radius_of_postal_code(postal_code, radius=50)
          location = Geocode.find_or_create_by_query(postal_code)
          self.find_within_radius(location, radius)
        end

      end

      # Adds instance methods.
      module InstanceMethods
        
        def geocode
          geocoding.geocode if geocoding
        end
        
        # Return the entire address in one string.
        def full_address
          returning("") { |address|
            address << "#{geo_attribute(:street)}\n" unless geo_attribute(:street).blank?
            address << "#{geo_attribute(:city)}, " unless geo_attribute(:city).blank?
            address << "#{geo_attribute(:region)} " unless geo_attribute(:region).blank?
            address << "#{geo_attribute(:postal_code)}" unless geo_attribute(:postal_code).blank?
            address << " #{geo_attribute(:country)}" unless geo_attribute(:country).blank?
          }.strip
        end
        
        def distance_to(destination, units = :miles, formula = :haversine)
          self.geocode.distance_to(destination.geocode, units, formula)
        end
        
        # Set the latitude and longitude. 
        def attach_geocode
          geocode = Geocode.find_or_create_by_query(self.full_address)
          unless geocode == self.geocode || geocode.new_record?
            self.geocoding.destroy unless self.geocoding.blank?
            self.geocoding = Geocoding.new :geocode => geocode
            self.update_address self.acts_as_geocodable_options[:normalize_address]
          end
        end
        
        def update_address(force = false)
          unless self.geocode.blank?
            self.acts_as_geocodable_options[:address].each do |attribute,method|
              if self.respond_to?("#{method}=") && (self.send(method).blank? || force)
                self.send "#{method}=", self.geocode.send(attribute)
              end
            end
            update_without_callbacks
          end
        end
        
        def geo_attribute(attr_key)
          attr_name = self.acts_as_geocodable_options[:address][attr_key]
          attr_name && self.respond_to?(attr_name) ? self.send(attr_name) : nil
        end

      end
    end
  end
end