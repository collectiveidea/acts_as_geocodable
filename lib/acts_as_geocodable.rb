require 'active_record'

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

          has_many :geocodings, :as => :geocodable, :dependent => :destroy
          has_many :geocodes, :through => :geocodings
          
          after_save  :geocode          
          
          include CollectiveIdea::Acts::Geocodable::InstanceMethods
          extend CollectiveIdea::Acts::Geocodable::SingletonMethods
        end
        
      end

      module SingletonMethods
        
        def find_within_radius(location, radius=50, units=:miles)
          # Ensure valid floats
          latitude, longitude = location.latitude.to_f, location.longitude.to_f, radius.to_f
          class_name = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s
          # TODO: refactor so SQL is database agnostic
          return find_by_sql(
            ["SELECT #{table_name}.*, geocodes.latitude, geocodes.longitude, (#{Geocode.earth_radius(units)} * ACOS(
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
            "AND (#{Geocode.earth_radius(units)} * ACOS(
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
        
        # Return the entire address in one string.
        def full_address
          returning("") { |address|
            address << "#{geocodable_attribute(:street)}\n" unless geocodable_attribute(:street).blank?
            address << "#{geocodable_attribute(:city)}, " unless geocodable_attribute(:city).blank?
            address << "#{geocodable_attribute(:region)} " unless geocodable_attribute(:region).blank?
            address << "#{geocodable_attribute(:postal_code)}" unless geocodable_attribute(:postal_code).blank?
            address << " #{geocodable_attribute(:country)}" unless geocodable_attribute(:country).blank?
          }.strip
        end
        
        def distance_to(other, units=:miles)
          Geocode.distance self.geocodes.first, other.geocodes.first, units
        end     
        
        # Set the latitude and longitude. 
        def geocode(locations=[self.full_address])
          locations.each do |location|
            geocode = Geocode.find_or_create_by_query(location)
            geocode.on self unless geocode.new_record?
          end
          self.update_address(self.acts_as_geocodable_options[:normalize_address])
        end
        
        def update_address(force = false)
          unless self.geocodes.empty?
            self.acts_as_geocodable_options[:address].each do |attribute,method|
              if self.respond_to?("#{method}=") && (self.send(method).blank? || force)
                self.send "#{method}=", self.geocodes.last.send(attribute)
              end
            end
            update_without_callbacks
          end
        end
        
        def geocodable_attribute(attr_key)
          attr_name = self.acts_as_geocodable_options[:address][attr_key]
          attr_name && self.respond_to?(attr_name) ? self.send(attr_name) : nil
        end

      end
    end
  end
end