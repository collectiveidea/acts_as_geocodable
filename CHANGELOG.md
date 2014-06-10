## 2.0.0 / 2010-10-01

* Rewrite for Rails 3
* Implement new Rails 3/ARel finder syntax
* Double Rainbows 🌈🌈

## 0.2.1 / 2008-08-08

* Make results will_paginate-compatible

## 0.2.0 / 2007-10-27

* Add `validates_as_geocodable` ([Mark Van Holstyn](https://github.com/mvanholstyn))
* Allow address mapping to be a single field ([Mark Van Holstyn](https://github.com/mvanholstyn))

## 0.1.0

* Add `remote_location` to get a user's location based on his or her `remote_ip`
* Rename `:city` to `:locality` in address mapping to be consistent with Graticule 0.2

  Create a migration with:

  ```ruby
  rename_column :geocodes, :city, :locality
  ```
* Replace `#full_address` with `#to_location`
