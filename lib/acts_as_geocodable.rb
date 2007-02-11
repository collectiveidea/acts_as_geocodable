module CollectiveIdea
  module Acts #:nodoc:
    module Geocodable #:nodoc:
      
      def self.included(mod)
        mod.extend(ClassMethods)
      end

      module ClassMethods
        
        def acts_as_geocodable(options = {})
          options = {
            :address => {:street => :street, :city => :city, :region => :region, :postal_code => :postal_code, :country => :country},
            :normalize_address => false,
            :distance_column => 'distance',
            :units => :miles
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
        
        # * :origin
        #
        # * :farthest
        # * :nearest
        #
        # * :within
        # * :beyond
        # 
        def find(*args)
          options = extract_options_from_args! args
          origin = extract_origin_from_options! options
          if origin
            options[:units] ||= acts_as_geocodable_options[:units]
            add_distance_to_select!(origin, options)
            with_proximity!(args) do
              join_geocodes do
                geocode_conditions!(options, origin) do
                  super *args.push(options)
                end
              end
            end
          else
            super *args.push(options)
          end
        end
        
        def location_to_geocode(location)
          case location
          when Geocode then location
          when InstanceMethods then location.geocode
          when String, Fixnum then Geocode.find_or_create_by_query(location)
          end
        end
      
      private
      
        def extract_origin_from_options!(options)
          location_to_geocode(options.delete(:origin))
        end
        
        def add_distance_to_select!(origin, options)
          (options[:select] ||= "#{table_name}.*") << ", geocodes.*, #{sql_for_distance(origin, options[:units])} AS #{acts_as_geocodable_options[:distance_column]}"
        end
      
        def with_proximity!(args)
          if [:nearest, :farthest].include?(args.first)
            direction = args.first == :nearest ? "ASC" : "DESC"
            args[0] = :first
            with_scope :find => { :order => "#{acts_as_geocodable_options[:distance_column]} #{direction}"} do
              yield
            end
          else
            yield
          end
        end
        
        def join_geocodes(&block)
          with_scope :find => { :joins => "JOIN geocodings ON
              #{table_name}.#{primary_key} = geocodings.geocodable_id AND
                geocodings.geocodable_type = '#{class_name}'
              JOIN geocodes ON geocodings.geocode_id = geocodes.id" } do
            yield
          end
        end
        
        def geocode_conditions!(options, origin)
          conditions = []
          units = options.delete(:units)
          conditions << "#{sql_for_distance(origin, units)} <= #{options.delete(:within)}" if options[:within]
          conditions << "#{sql_for_distance(origin, units)} > #{options.delete(:beyond)}" if options[:beyond]
          if conditions.empty?
            yield
          else
            with_scope(:find => { :conditions => conditions.join(" AND ") }) { yield }
          end
        end
        
        def sql_for_distance(origin, units = acts_as_geocodable_options[:units])
          Graticule::Distance::Spherical.to_sql(
            :latitude => origin.latitude,
            :longitude => origin.longitude,
            :latitude_column => "geocodes.latitude",
            :longitude_column => "geocodes.longitude",
            :units => units
          )
        end
        
      end

      # Adds instance methods.
      module InstanceMethods
        
        # Get the geocode for this model
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
        
        # Get the distance to the given destination. The destination can be an
        # acts_as_geocodable model, a Geocode, or a string
        #
        #   myhome.distance_to "Chicago, IL"
        #   myhome.distance_to "49423"
        #   myhome.distance_to other_model
        #
        # == Options
        # * <tt>:units</tt>: <tt>:miles</tt> or <tt>:kilometers</tt>
        # * <tt>:formula</tt>: The formula to use to calculate the distance. This can
        #   be any formula supported by Graticule. The default is <tt>:haversine</tt>.
        #  
        def distance_to(destination, options = {})
          options = {
            :units => self.class.acts_as_geocodable_options[:units],
            :formula => :haversine
          }.merge(options)
          
          geocode = self.class.location_to_geocode(destination)
          self.geocode.distance_to(geocode, options[:units], options[:formula])
        end
        
      protected
        
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