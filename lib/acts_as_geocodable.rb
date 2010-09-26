require 'acts_as_geocodable/geocoding'
require 'acts_as_geocodable/geocode'
require 'acts_as_geocodable/remote_location'

module ActiveSupport::Callbacks::ClassMethods
  def without_callback(*args, &block)
    skip_callback(*args)
    yield
    set_callback(*args)
  end
end

module ActsAsGeocodable #:nodoc:
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

    define_callbacks :geocoding

    has_one :geocoding, :as => :geocodable, :include => :geocode, :dependent => :destroy

    after_save :attach_geocode

    # Would love to do a simpler scope here, like:
    # scope :with_geocode_fields, includes(:geocoding)
    # But we need to use select() and it would get overwritten.
    scope :with_geocode_fields, lambda {
      joins("JOIN geocodings ON
          #{table_name}.#{primary_key} = geocodings.geocodable_id AND
            geocodings.geocodable_type = '#{model_name}'
          JOIN geocodes ON geocodings.geocode_id = geocodes.id")
    }

    # Use ActiveRecord ARel style syntax for finding records.
    #
    #   Model.origin("Chicago, IL", :within => 10)
    #
    # a +distance+ attribute indicating the distance
    # to the origin is added to each of the results:
    #
    #   Model.origin("Portland, OR").first.distance #=> 388.383
    #
    # == Options
    #
    # * <tt>origin</tt>: A Geocode, String, or geocodable model that specifies
    #   the origin
    # * <tt>:within</tt>: Limit to results within this radius of the origin
    # * <tt>:beyond</tt>: Limit to results outside of this radius from the origin
    # * <tt>:units</tt>: Units to use for <tt>:within</tt> or <tt>:beyond</tt>.
    #   Default is <tt>:miles</tt> unless specified otherwise in the +acts_as_geocodable+
    #   declaration.
    #
    scope :origin, lambda {|*args|
      origin = args[0]
      options = {
        :units => acts_as_geocodable_options[:units],
      }.merge(args[1] || {})
      distance_sql = sql_for_distance(origin, options[:units])

      scope = with_geocode_fields.select("#{table_name}.*, #{distance_sql} AS
           #{acts_as_geocodable_options[:distance_column]}")

      scope = scope.where("#{distance_sql} >  #{options[:beyond]}") if options[:beyond]
      scope = scope.where("#{distance_sql} <= #{options[:within]}") if options[:within]
      scope
    }

    scope :near, order("#{acts_as_geocodable_options[:distance_column]} ASC")
    scope :far, order("#{acts_as_geocodable_options[:distance_column]} DESC")

    include ActsAsGeocodable::Model
  end

  module Model
    extend ActiveSupport::Concern

    module ClassMethods

      # Find the nearest location to the given origin
      #
      #   Model.origin("Grand Rapids, MI").nearest
      #
      def nearest
        near.first
      end

      # Find the farthest location to the given origin
      #
      #   Model.origin("Grand Rapids, MI").farthest
      #
      def farthest
        far.first
      end

      # Convert the given location to a Geocode
      def location_to_geocode(location)
        case location
        when Geocode then location
        when InstanceMethods then location.geocode
        when String, Fixnum then Geocode.find_or_create_by_query(location)
        end
      end

      # Validate that the model can be geocoded
      #
      # Options:
      # * <tt>:message</tt>: Added to errors base (Default: Address could not be geocoded.)
      # * <tt>:allow_nil</tt>: If all the address attributes are blank, then don't try to
      #   validate the geocode (Default: false)
      # * <tt>:precision</tt>: Require a minimum geocoding precision
      #
      # validates_as_geocodable also takes a block that you can use to performa additional
      # checks on the geocode. If this block returns false, then validation will fail.
      #
      #   validates_as_geocodable do |geocode|
      #     geocode.country == "US"
      #   end
      #
      def validates_as_geocodable(options = {})
        options = options.reverse_merge :message => "Address could not be geocoded.", :allow_nil => false
        validate do |model|
          is_blank = model.to_location.attributes.except(:precision).all?(&:blank?)
          unless options[:allow_nil] && is_blank
            geocode = model.send :attach_geocode
            if !geocode ||
                (options[:precision] && geocode.precision < options[:precision]) ||
                (block_given? && yield(geocode) == false)
              model.errors.add :base, options[:message]
            end
          end
        end
      end

    private

      def sql_for_distance(origin, units = acts_as_geocodable_options[:units])
        origin = location_to_geocode(origin)
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
        Graticule::Location.new.tap do |location|
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
        units = options[:units] || acts_as_geocodable_options[:units]
        formula = options[:formula] || :haversine

        geocode = self.class.location_to_geocode(destination)
        self.geocode.distance_to(geocode, units, formula)
      end

    protected

      # Perform the geocoding
      def attach_geocode
        new_geocode = Geocode.find_or_create_by_location self.to_location unless self.to_location.blank?
        if new_geocode && self.geocode != new_geocode
          run_callbacks :geocoding do
            self.geocoding = Geocoding.new :geocode => new_geocode
            self.update_address self.acts_as_geocodable_options[:normalize_address]
          end
        elsif !new_geocode && self.geocoding
          self.geocoding.destroy
        end
        new_geocode
      rescue Graticule::Error => e
        logger.warn e.message
      end


      def update_address(force = false) #:nodoc:
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

          self.class.without_callback(:save, :after, :attach_geocode) do
            save
          end
        end
      end

      def geo_attribute(attr_key) #:nodoc:
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