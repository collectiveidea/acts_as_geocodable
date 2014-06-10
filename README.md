# acts_as_geocodable

[![Gem Version](https://img.shields.io/gem/v/acts_as_geocodable.svg?style=flat)](http://rubygems.org/gems/acts_as_geocodable)
[![Build Status](https://img.shields.io/travis/collectiveidea/acts_as_geocodable/master.svg?style=flat)](https://travis-ci.org/collectiveidea/acts_as_geocodable)
[![Code Climate](https://img.shields.io/codeclimate/github/collectiveidea/acts_as_geocodable.svg?style=flat)](https://codeclimate.com/github/collectiveidea/acts_as_geocodable)
[![Code Coverage](http://img.shields.io/codeclimate/coverage/github/collectiveidea/acts_as_geocodable.svg?style=flat)](https://codeclimate.com/github/collectiveidea/acts_as_geocodable)
[![Dependency Status](https://img.shields.io/gemnasium/collectiveidea/acts_as_geocodable.svg?style=flat)](https://gemnasium.com/collectiveidea/acts_as_geocodable)

acts_as_geocodable helps you build geo-aware applications. It automatically geocodes your models when they are saved, giving you the ability to search by location and calculate distances between records.

**Beginning with version 2, we require Rails 3. Use one of the 1.0.x tags to work with Rails 2.3.**

We've adopted the ARel style syntax for finding records.

## Usage

```ruby
event = Event.create(
  street: "777 NE Martin Luther King, Jr. Blvd.",
  locality: "Portland",
  region: "Oregon",
  postal_code: 97232
)

event.geocode.latitude  # => 45.529100000000
event.geocode.longitude # => -122.644200000000

event.distance_to("49423") # => 1807.66560483205

Event.origin("97232", within: 50)

Event.origin("Portland, OR").nearest
```

## Installation

Install as a gem

```
gem install acts_as_geocodable
```

or add it to your Gemfile

```ruby
gem "acts_as_geocodable"
```

[Graticule](http://github.com/collectiveidea/graticule) is used for all the heavy lifting and will be installed too.

## Upgrading

Before October 2008, precision wasn't included in the `Geocode` model. Make sure you add a string precision column to your geocode table if you're upgrading from an older version, and update Graticule.

Also, if you're upgrading from a previous version of this plugin, note that `:city` has been renamed to `:locality` to be consistent with Graticule 0.2. Create a migration that has:

```ruby
rename_column :geocodes, :city, :locality
```

Also remember to change your mapping in your geocodable classes to use the `:locality` key instead of `:city`:

```ruby
class Event < ActiveRecord::Base
  acts_as_geocodable address: { street: :address1, locality: :city, region: :state, postal_code: :zip }
end
```

## Configuration

Create the required tables

```
rails generate acts_as_geocodable
rake db:migrate
```

Set the default geocoder in your environment.rb file.

```ruby
Geocode.geocoder = Graticule.service(:yahoo).new("your_api_key")
```

Then, in each model you want to make geocodable, add `acts_as_geocodable`.

```ruby
class Event < ActiveRecord::Base
  acts_as_geocodable
end
```

The only requirement is that your model must have address fields. By default, acts_as_geocodable looks for attributes called _street_, _locality_, _region_, _postal_code_, and _country_. To change these, you can provide a mapping in the `:address` option:

```ruby
class Event < ActiveRecord::Base
  acts_as_geocodable address: { street: :address1, locality: :city, region: :state, postal_code: :zip }
end
```

If that doesn't meet your needs, simply override the default `to_location` method in your model, and return a `Graticule::Location` with those attributes set.

acts_as_geocodable can also update your address fields with the data returned from the geocoding service:

```ruby
class Event < ActiveRecord::Base
  acts_as_geocodable normalize_address: true
end
```

## IP-based Geocoding

acts_as_geocodable adds a `remote_location` method in your controllers that uses http://hostip.info to guess remote users location based on their IP address.

```ruby
def index
  @nearest = Store.origin(remote_location).nearest if remote_location
  @stores = Store.all
end
```

Keep in mind that IP-based geocoding is not always accurate, and often will not return any results.

## Contributing

In the spirit of [free software](http://www.fsf.org/licensing/essays/free-sw.html), **everyone** is encouraged to help improve this project.

Here are some ways **you** can contribute:

* using alpha, beta, and prerelease versions
* reporting bugs
* suggesting new features
* writing or editing documentation
* writing specifications
* writing code (**no patch is too small**: fix typos, add comments, clean up inconsistent whitespace)
* refactoring code
* closing [issues](https://github.com/collectiveidea/acts_as_geocodable/issues/)
* reviewing patches

## Submitting an Issue

We use the [GitHub issue tracker](https://github.com/collectiveidea/acts_as_geocodable/issues/) to track bugs
and features. Before submitting a bug report or feature request, check to make sure it hasn't already
been submitted. You can indicate support for an existing issuse by voting it up. When submitting a
bug report, please include a [Gist](https://gist.github.com/) that includes a stack trace and any
details that may be necessary to reproduce the bug, including your gem version, Ruby version, and
operating system. Ideally, a bug report should include a pull request with failing specs.

## Submitting a Pull Request

1. Fork the project.
2. Create a topic branch.
3. Implement your feature or bug fix.
4. Add specs for your feature or bug fix.
5. Run `bundle exec rake`. If your changes are not 100% covered and passing, go back to step 4.
6. Commit and push your changes.
7. Submit a pull request. Please do not include changes to the gemspec, version, or history file. (If you want to create your own version for some reason, please do so in a separate commit.)

### To Do

* configurable formulas
