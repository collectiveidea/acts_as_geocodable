module CollectiveIdea #:nodoc:
  module Acts #:nodoc:
    module Geocodable #:nodoc:
      
      def self.included(mod)
        mod.extend(ClassMethods)
      end

      module ClassMethods
        
        # Make a model geocodable.
        #
        #  class Event < ActiveRecord::Base
        #    acts_as_geocodable
        #  end
        #
        # == Options
        # * <tt>:address</tt>: A hash that maps geocodable attirbutes (<tt>:street</tt>,
        #   <tt>:locality</tt>, <tt>:region</tt>, <tt>:postal_code</tt>, <tt>:country</tt>)
        #   to your model's address fields, or a symbol to store the entire address in one field
        # * <tt>:normalize_address</tt>: If set to true, you address fields will be updated
        #   using the address fields returned by the geocoder. (Default is +false+)
        # * <tt>:units</tt>: Default units-<tt>:miles</tt> or <tt>:kilometers</tt>-used for
        #   distance calculations and queries. (Default is <tt>:miles</tt>)
        #
        def acts_as_geocodable(options = {})
          options = {
            :address => {
              :street => :street, :locality => :locality, :region => :region,
              :postal_code => :postal_code, :country => :country},
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
        
        # Extends ActiveRecord's find method to be geo-aware.
        #
        #   Model.find(:all, :within => 10, :origin => "Chicago, IL")
        #
        # Whenever find is called with an <tt>:origin</tt>, a +distance+ attribute
        # indicating the distance to the origin is added to each of the results:
        #
        #   Model.find(:first, :origin => "Portland, OR").distance #=> 388.383
        #
        # +acts_as_geocodable+ adds 2 other retrieval approaches to ActiveRecord's default
        # find by id, find <tt>:first</tt>, and find <tt>:all</tt>:
        #
        # * <tt>:nearest</tt>: find the nearest location to the given origin
        # * <tt>:farthest</tt>: find the farthest location from the given origin
        #
        #   Model.find(:nearest, :origin => "Grand Rapids, MI")
        #
        # == Options
        #
        # * <tt>:origin</tt>: A Geocode, String, or geocodable model that specifies
        #   the origin
        # * <tt>:within</tt>: Limit to results within this radius of the origin
        # * <tt>:beyond</tt>: Limit to results outside of this radius from the origin
        # * <tt>:units</tt>: Units to use for <tt>:within</tt> or <tt>:beyond</tt>.
        #   Default is <tt>:miles</tt> unless specified otherwise in the +acts_as_geocodable+
        #   declaration.
        #
        def find(*args)
          options = args.extract_options!
          origin = location_to_geocode options.delete(:origin)
          if origin
            options[:units] ||= acts_as_geocodable_options[:units]
            add_distance_to_select!(origin, options)
            with_proximity!(args, options) do
              geocode_conditions!(options, origin) do
                join_geocodes { super *args.push(options) }
              end
            end
          else
            super *args.push(options)
          end
        end
        
        # Extends ActiveRecord's count method to be geo-aware.
        #
        #   Model.count(:within => 10, :origin => "Chicago, IL")
        #
        # == Options
        #
        # * <tt>:origin</tt>: A Geocode, String, or geocodable model that specifies
        #   the origin
        # * <tt>:within</tt>: Limit to results within this radius of the origin
        # * <tt>:beyond</tt>: Limit to results outside of this radius from the origin
        # * <tt>:units</tt>: Units to use for <tt>:within</tt> or <tt>:beyond</tt>.
        #   Default is <tt>:miles</tt> unless specified otherwise in the +acts_as_geocodable+
        #   declaration.
        #
        def count(*args)
          options = args.extract_options!
          origin = location_to_geocode options.delete(:origin)
          if origin
            options[:units] ||= acts_as_geocodable_options[:units]
            with_proximity!(args, options) do
              geocode_conditions!(options, origin) do
                join_geocodes { super *args.push(options) }
              end
            end
          else
            super *args.push(options)
          end
        end
  
        # Convert the given location to a Geocode
        def location_to_geocode(location)
          case location
          when Geocode then location
          when InstanceMethods then location.geocode
          when String, Fixnum then Geocode.find_or_create_by_query(location)
          end
        end
        
        def validates_as_geocodable(options = {})
          options = options.reverse_merge :message => "Address could not be geocoded.", :allow_nil => false
          validate do |geocodable|
            if !(options[:allow_nil] && geocodable.to_location.attributes.all?(&:blank?)) &&
                !Geocode.find_or_create_by_location(geocodable.to_location)
              geocodable.errors.add_to_base options[:message]
            end
          end
        end
      
      private
      
        def add_distance_to_select!(origin, options)
          (options[:select] ||= "#{table_name}.*") <<
            ", #{sql_for_distance(origin, options[:units])} AS
            #{acts_as_geocodable_options[:distance_column]}"
        end
      
        def with_proximity!(args, options)
          if [:nearest, :farthest].include?(args.first)
            raise ArgumentError, ":include cannot be specified with :nearest and :farthest" if options[:include]
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
          units = options.delete(:units)
          conditions = []
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

      module InstanceMethods
        
        # Get the geocode for this model
        def geocode
          geocoding.geocode if geocoding
        end
        
        # Create a Graticule::Location
        def to_location
          returning Graticule::Location.new do |location|
            [:street, :locality, :region, :postal_code, :country].each do |attr|
              location.send "#{attr}=", geo_attribute(attr)
            end
          end
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
        
        # Perform the geocoding
        def attach_geocode
          geocode = Geocode.find_or_create_by_location self.to_location unless self.to_location.attributes.all?(&:blank?)
          if geocode.nil? || geocode != self.geocode || geocode.new_record?
            self.geocoding.destroy unless self.geocoding.blank?
            if geocode
              self.geocoding = Geocoding.new :geocode => geocode
              self.update_address self.acts_as_geocodable_options[:normalize_address]
            end
          end
        rescue Graticule::Error => e
          logger.warn e.message
        end
        
        def update_address(force = false)
          unless self.geocode.blank?
            if self.acts_as_geocodable_options[:address].is_a? Symbol
              method = self.acts_as_geocodable_options[:address]
              if self.respond_to?("#{method}=") && (self.send(method).blank? || force)
                self.send "#{method}=", self.geocode.to_location.to_s
              end
            else
              self.acts_as_geocodable_options[:address].each do |attribute,method|
                if self.respond_to?("#{method}=") && (self.send(method).blank? || force)
                  self.send "#{method}=", self.geocode.send(attribute)
                end
              end
            end
            
            update_without_callbacks
          end
        end
        
        def geo_attribute(attr_key)
          if self.acts_as_geocodable_options[:address].is_a? Symbol
            attr_name = self.acts_as_geocodable_options[:address]
            attr_key == :street ? self.send(attr_name) : nil
          else
            attr_name = self.acts_as_geocodable_options[:address][attr_key]
            attr_name && self.respond_to?(attr_name) ? self.send(attr_name) : nil
          end
        end
      end
    end
  end
end