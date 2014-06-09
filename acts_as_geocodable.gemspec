# encoding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'acts_as_geocodable/version'

Gem::Specification.new do |spec|
  spec.name    = 'acts_as_geocodable'
  spec.version = ActsAsGeocodable::VERSION

  spec.authors     = ['Daniel Morrison', 'Brandon Keepers', 'Brian Ryckbost']
  spec.email       = 'info@collectiveidea.com'
  spec.summary     = 'Simple geocoding for Active Record models'
  spec.description = 'Simple geocoding for Active Record models. See the README for more details.'
  spec.homepage    = 'https://github.com/collectiveidea/acts_as_geocodable'
  spec.license     = 'MIT'

  spec.files      = `git ls-files -z`.split("\x0")
  spec.test_files = spec.files.grep(/^spec/)

  spec.add_dependency 'graticule', '~> 2.0'
  spec.add_dependency 'rails', '>= 2.3', '< 4.2'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake', '~> 10.3'
end
