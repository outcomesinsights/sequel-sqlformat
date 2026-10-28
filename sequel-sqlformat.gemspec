# frozen_string_literal: true

require_relative "lib/sequel/sqlformat/version"

Gem::Specification.new do |spec|
  spec.name = "sequel-sqlformat"
  spec.version = Sequel::SQLFormat::VERSION
  spec.authors = [ "Ryan Duryea" ]
  spec.email = [ "aguynamedryan@gmail.com" ]

  spec.summary = "A Sequel extension that formats SQL, fast, with the Rust sqlformat crate"
  spec.description = "Adds Database#format_sql and Dataset#formatted_sql to Sequel. Formatting runs inside " \
                     "the Ruby process through a native extension (magnus) that wraps the Rust sqlformat " \
                     "crate, so no external process starts and many statements format in milliseconds."
  spec.homepage = "https://github.com/outcomesinsights/sequel-sqlformat"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # An allowlist, not `git ls-files`, so that tracker and scratch files never ship.
  spec.files = %w[CHANGELOG.md LICENSE README.md Cargo.toml Cargo.lock] +
               Dir["lib/**/*.rb"] + Dir["ext/**/*.{rb,rs,toml}"]
  spec.require_paths = [ "lib" ]
  spec.extensions = [ "ext/sequel_sqlformat/extconf.rb" ]

  spec.add_dependency "sequel", "~> 5.0"
  # Needed only to build the source gem. A precompiled platform gem needs no Rust.
  spec.add_dependency "rb_sys", "~> 0.9"
end
