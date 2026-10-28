# frozen_string_literal: true

require_relative "sqlformat/version"

# A precompiled gem keeps one library per Ruby minor version under
# lib/sequel/sqlformat/<major.minor>/. A gem built from source puts it in
# lib/sequel/sqlformat/.
begin
  ruby_minor = RUBY_VERSION[/\A\d+\.\d+/]
  require_relative "sqlformat/#{ruby_minor}/sequel_sqlformat"
rescue LoadError
  require_relative "sqlformat/sequel_sqlformat"
end

module Sequel
  # Formats SQL inside the Ruby process with the Rust `sqlformat` crate. The crate
  # splits SQL into tokens and does not parse it, so it accepts any dialect and never
  # fails on unknown syntax. This needs no database; the `sqlformat` Sequel extension
  # (lib/sequel/extensions/sqlformat.rb) adds it to databases and datasets.
  module SQLFormat
    DIALECTS = %i[generic postgresql sqlserver].freeze

    # The crate's own defaults.
    DEFAULTS = { indent: 2, uppercase: nil, lines_between_queries: 1, dialect: :generic }.freeze

    # indent: spaces for each indentation level (0 to 255).
    # uppercase: true uppercases keywords, false lowercases them, nil keeps them.
    # lines_between_queries: line breaks after each statement (0 to 255).
    # dialect: :postgresql adds array syntax. :sqlserver adds [brackets] and @variables.
    def self.format(sql, indent: 2, uppercase: nil, lines_between_queries: 1, dialect: :generic)
      raise TypeError, "sql must be a String, got #{sql.class}" unless sql.is_a?(String)
      raise ArgumentError, "unknown dialect #{dialect.inspect}; expected one of #{DIALECTS.inspect}" unless DIALECTS.include?(dialect.to_sym)
      raise ArgumentError, "indent must be an Integer from 0 to 255" unless indent.is_a?(Integer) && indent.between?(0, 255)
      raise ArgumentError, "lines_between_queries must be an Integer from 0 to 255" unless lines_between_queries.is_a?(Integer) && lines_between_queries.between?(0, 255)
      raise ArgumentError, "uppercase must be true, false or nil" unless [ true, false, nil ].include?(uppercase)

      native_format(sql.encode(Encoding::UTF_8), indent, uppercase, lines_between_queries, dialect.to_s)
    end

    # The crate dialect for a Sequel database type. Every type the crate has no mode
    # for, such as DuckDB, Spark, SQLite and MySQL, gets the generic mode.
    def self.dialect_for(database_type)
      case database_type
      when :postgres then :postgresql
      when :mssql then :sqlserver
      else :generic
      end
    end
  end
end
