## 2.1.0 / Unreleased

* [ENHANCEMENT] Whitelist attributes for mass assignment
* [FEATURE] Add Rails 4 compatibility
* [ENHANCEMENT] Add runtime dependency on Rails
* [ENHANCEMENT] Adhere to GitHub's Ruby Style Guide
* [BUGFIX] Fix dependency requirement sequence

## 2.0.3 / 2011-11-15

* [BUGFIX] Fix class attribute management across Rails versions

## 2.0.2 / 2011-01-06

* [PERFORMANCE] Optimize query clause ordering

## 2.0.1 / 2010-11-15

* [BUGFIX] Explicitly typecast PostgreSQL types
* [BUGFIX] Fix bug where origin/target locations are equal

## 2.0.0 / 2010-10-01

* [ENHANCEMENT] Rewrite for Rails 3
* [FEATURE] Implement new Rails 3/ARel finder syntax
* [FEATURE] Double Rainbows 🌈🌈

## 1.0.4 / 2010-09-20

* [ENHANCEMENT] Use `tap` rather than `returning`

## 1.0.3 / 2010-03-17

* [ENHANCEMENT] Add the `graticule` runtime gem dependency

## 1.0.2 / 2010-02-04

* [FEATURE] Allow `validates_as_geocodable` to accept a block

## 1.0.1 / 2009-12-16

* [FEATURE] Allow `validates_as_geocodable` to accept a `:precision` option

## 1.0.0 / 2009-10-21

* [FEATURE] Add an `after_geocoding` callback
* [PERFORMANCE] Add appropriate database indexes

## 0.2.1 / 2008-08-08

* [FEATURE] Make results will_paginate-compatible

## 0.2.0 / 2007-10-27

* [FEATURE] Add `validates_as_geocodable` ([Mark Van Holstyn](https://github.com/mvanholstyn))
* [FEATURE] Allow address mapping to be a single field ([Mark Van Holstyn](https://github.com/mvanholstyn))

## 0.1.0 / 2007-03-20

* [FEATURE] Add `remote_location` to get a user's location based on his or her `remote_ip`
* [ENHANCEMENT] Rename `:city` to `:locality` in address mapping to be consistent with Graticule 0.2

  Create a migration with:

  ```ruby
  rename_column :geocodes, :city, :locality
  ```
* [ENHANCEMENT] Replace `#full_address` with `#to_location`
