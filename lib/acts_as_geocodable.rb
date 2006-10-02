require 'active_record'
require 'xmlrpc/client'

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
          write_inheritable_attribute(:acts_as_geocodable_options, {
            :geocodable_type => ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s,
            :normalize_address => options[:normalize_address]
          })
          
          class_inheritable_reader :acts_as_geocodable_options
                    
          has_many :geocodings, :as => :geocodable, :dependent => true
          has_many :geocodes, :through => :geocodings
          
          after_save  :attach_geocode          
          
          include CollectiveIdea::Acts::Geocodable::InstanceMethods
          extend CollectiveIdea::Acts::Geocodable::SingletonMethods
        end
        
      end

      module SingletonMethods
        
        def find_within_radius(location, radius=50, units=:miles)

          # Ensure valid floats
          latitude, longitude = location.latitude.to_f, location.longitude.to_f, radius.to_f
          
          return find_by_sql(
            "SELECT #{table_name}.*, geocodes.latitude, geocodes.longitude, (#{Geocode.earth_radius(units)} * ACOS(
                                      COS(RADIANS(`latitude`))*COS(RADIANS(`longitude`))
                                      	* COS(RADIANS('#{latitude}'))*COS(RADIANS('#{longitude}'))
                                      + COS(RADIANS(`latitude`))*SIN(RADIANS(`longitude`))
                                      	* COS(RADIANS('#{latitude}'))*SIN(RADIANS('#{longitude}'))
                                      + SIN(RADIANS(`latitude`))
                                      	* SIN(RADIANS('#{latitude}'))
                                      ) ) as distance
                                      FROM #{table_name}, geocodes, geocodings " +
            "WHERE #{table_name}.#{primary_key} = geocodings.geocodable_id " +
            "AND geocodings.geocodable_type = '#{acts_as_geocodable_options[:geocodable_type]}' " +
            "AND geocodings.geocode_id = geocodes.id "+
            "AND (#{Geocode.earth_radius(units)} * ACOS(
                                      COS(RADIANS(`latitude`))*COS(RADIANS(`longitude`))
                                      	* COS(RADIANS('#{latitude}'))*COS(RADIANS('#{longitude}'))
                                      + COS(RADIANS(`latitude`))*SIN(RADIANS(`longitude`))
                                      	* COS(RADIANS('#{latitude}'))*SIN(RADIANS('#{longitude}'))
                                      + SIN(RADIANS(`latitude`))
                                      	* SIN(RADIANS('#{latitude}'))
                                      ) ) <= #{radius} " +
            "ORDER BY distance")
        end
        
        def find_within_radius_of_zip(zip, radius=50)
          location = Geocode.find_or_create_by_query(zip)
          self.find_within_radius(location, radius)
        end
        
        # Unimplemented. 
        def distance_between_in_miles(first, second)
          
        end
        
        def distance_between_in_kilometers(first, second)
          
        end
        
        def distance_away_in_miles(other)
          self.distance_between_in_miles self, other
        end
        
        def distance_away_in_kilometers(other)
          self.distance_between_in_kilometers self, other
        end
      end

      # Adds instance methods.
      module InstanceMethods
        
        # Return the entire address in one string.
        def full_address
          address = ''
          address += self.street+"\n" unless self.street.blank?
          address += self.city+', ' unless self.city.blank?
          address += self.state+' ' unless self.state.blank?
          address += self.zip unless self.zip.blank?
          address
        end        
        
        # Set the latitude and longitude. 
        def geocode(locations=[self.full_address])
          locations.each do |location|
            geocode = Geocode.find_or_create_by_query(location)
            self.geocodes << geocode unless geocode.new_record?
          end
        end
        
        def attach_geocode
          # Only geocode if we haven't before.
          if self.geocodes.empty?
            self.send :geocode
          end
          
          if self.acts_as_geocodable_options[:normalize_address]
            self.update_address
          end
        end
        
        def update_address
          unless self.geocodes.empty?
            methods = [:street, :city, :state, :zip, :country]
            methods.each do |method|
              if self.respond_to?(method) && self.send(method).blank?
                self.update_attribute(method, self.geocodes.first.send(method) )
              end
            end
          end
        end
         
      end

    end
  end
end