ActiveRecord::Schema.define(:version => 1) do
  
  create_table "geocodes", :force => true do |t|
    t.column "latitude",  :decimal, :precision => 15, :scale => 12
    t.column "longitude", :decimal, :precision => 15, :scale => 12
    t.column "query",     :string
    t.column "street",    :string
    t.column "locality",      :string
    t.column "region",     :string
    t.column "postal_code", :string
    t.column "country",   :string
  end

  add_index "geocodes", ["query"], :name => "geocodes_query_index", :unique => true
  add_index "geocodes", ["latitude"], :name => "geocodes_latitude_index"
  add_index "geocodes", ["longitude"], :name => "geocodes_longitude_index"

  create_table "geocodings", :force => true do |t|
    t.column "geocodable_id",   :integer
    t.column "geocode_id",      :integer
    t.column "geocodable_type", :string
  end

  add_index "geocodings", ["geocodable_id"], :name => "geocodings_geocodable_id_index"
  add_index "geocodings", ["geocode_id"], :name => "geocodings_geocode_id_index"
  add_index "geocodings", ["geocodable_type"], :name => "geocodings_geocodable_type_index"
  
  create_table "vacations", :force => true do |t|
    t.column "name", :string
    t.column "street", :string
    t.column "locality", :string
    t.column "region", :string
    t.column "postal_code", :string
    t.column "city_id", :integer
  end
  
  create_table "validated_vacations", :force => true do |t|
    t.column "name", :string
    t.column "street", :string
    t.column "locality", :string
    t.column "region", :string
    t.column "postal_code", :string
  end
  
  create_table "address_blob_vacations", :force => true do |t|
    t.column "name", :string
    t.column "address", :string
  end
  
  create_table "callback_locations", :force => true do |t|
    t.column "name", :string
    t.column "address", :string
  end
    
  create_table "cities", :force => true do |t|
    t.column "name", :string
    t.column "zip", :string
  end
  
end