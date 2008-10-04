class <%= class_name %> < ActiveRecord::Migration
  def self.up
    create_table "geocodes" do |t|
      t.column "latitude", :decimal, :precision => 15, :scale => 12
      t.column "longitude", :decimal, :precision => 15, :scale => 12
      t.column "query", :string
      t.column "street", :string
      t.column "locality", :string
      t.column "region", :string
      t.column "postal_code", :string
      t.column "country", :string
      t.column "precision", :string
    end

    add_index "geocodes", ["longitude"], :name => "geocodes_longitude_index"
    add_index "geocodes", ["latitude"], :name => "geocodes_latitude_index"
    add_index "geocodes", ["query"], :name => "geocodes_query_index", :unique => true
    add_index "geocodes", ["locality"], :name => "geocodes_locality_index"
    add_index "geocodes", ["region"], :name => "geocodes_region_index"
    add_index "geocodes", ["postal_code"], :name => "geocodes_postal_code_index"
    add_index "geocodes", ["country"], :name => "geocodes_country_index"
    add_index "geocodes", ["precision"], :name => "geocodes_precision_index"
    

    create_table "geocodings" do |t|
      t.column "geocodable_id", :integer
      t.column "geocode_id", :integer
      t.column "geocodable_type", :string
    end

    add_index "geocodings", ["geocodable_type"], :name => "geocodings_geocodable_type_index"
    add_index "geocodings", ["geocode_id"], :name => "geocodings_geocode_id_index"
    add_index "geocodings", ["geocodable_id"], :name => "geocodings_geocodable_id_index"
  end

  def self.down
    drop_table  :geocodes
    drop_table  :geocodings
  end
end
