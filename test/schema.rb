ActiveRecord::Schema.define(:version => 1) do
  
  create_table "geocodes", :force => true do |t|
    t.column "latitude",  :float
    t.column "longitude", :float
    t.column "query",     :string
    t.column "street",    :string
    t.column "city",      :string
    t.column "state",     :string
    t.column "zip",       :string
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
    t.column "city", :string
    t.column "state", :string
  end
  
  create_table "cities", :force => true do |t|
    t.column "name", :string
  end
  
end