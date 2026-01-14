# -*- encoding: utf-8 -*-
# stub: ice_cube 0.17.0 ruby lib

Gem::Specification.new do |s|
  s.name = "ice_cube".freeze
  s.version = "0.17.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/ice-cube-ruby/ice_cube/blob/master/CHANGELOG.md", "wiki_uri" => "https://github.com/ice-cube-ruby/ice_cube/wiki" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["John Crepezzi".freeze]
  s.date = "2024-07-18"
  s.description = "ice_cube is a recurring date library for Ruby.  It allows for quick, programatic expansion of recurring date rules.".freeze
  s.email = "john@crepezzi.com".freeze
  s.homepage = "https://ice-cube-ruby.github.io/ice_cube/".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.11".freeze
  s.summary = "Ruby Date Recurrence Library".freeze

  s.installed_by_version = "3.6.9".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["> 3".freeze])
  s.add_development_dependency(%q<standard>.freeze, [">= 0".freeze])
end
