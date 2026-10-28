# frozen_string_literal: true

#
# The sqlformat extension formats SQL for reading: one clause per line, indented
# subqueries, and optionally uppercase keywords. It formats inside the Ruby process
# with the Rust `sqlformat` crate, so no external process starts.
#
# Load it into a database:
#
#   DB.extension :sqlformat
#
#   DB[:items].where(id: 1).formatted_sql
#   # => "SELECT\n  *\nFROM\n  \"items\"\nWHERE\n  (\"id\" = 1)"
#
#   DB.format_sql("select a from t")   # any SQL string
#
# Or into one dataset only:
#
#   DB[:items].extension(:sqlformat).formatted_sql
#
# The crate's SQL dialect comes from the database type: :postgresql for PostgreSQL,
# :sqlserver for Microsoft SQL Server, and :generic for every other database.
#
# The default options are the crate's defaults (2 spaces, keyword case unchanged, one
# line break between statements). Change them for a database, either when connecting
# or before the database is frozen:
#
#   DB = Sequel.connect(url, sqlformat: { uppercase: true, indent: 4 })
#   DB.sqlformat_options = { uppercase: true }
#
# or for one call:
#
#   DB[:items].formatted_sql(uppercase: false)
#
# The crate works on tokens and does not parse SQL. It changes only whitespace and,
# with uppercase: true or false, the case of keywords. With uppercase: true or false,
# an unquoted identifier that is also a keyword changes case too.
#
# Related module: Sequel::SQLFormat

require_relative "../sqlformat"

module Sequel
  module SQLFormat
    OPTION_KEYS = DEFAULTS.keys.freeze

    # Checks option keys here, so a typo fails where it is written. The values are
    # checked by SQLFormat.format.
    def self.check_options!(opts)
      raise TypeError, "sqlformat options must be a Hash, got #{opts.class}" unless opts.is_a?(Hash)

      unknown = opts.keys - OPTION_KEYS
      raise ArgumentError, "unknown sqlformat option(s) #{unknown.inspect}; expected #{OPTION_KEYS.inspect}" unless unknown.empty?

      opts
    end

    module DatabaseMethods
      def self.extended(db)
        db.instance_exec do
          @sqlformat_options = SQLFormat.check_options!(opts.fetch(:sqlformat, {})).dup.freeze
        end
        db.extend_datasets(DatasetMethods)
      end

      # The options this database passes to SQLFormat.format. Per-call options win.
      attr_reader :sqlformat_options

      def sqlformat_options=(opts)
        @sqlformat_options = SQLFormat.check_options!(opts).dup.freeze
      end

      # Formats any SQL string with this database's dialect and options.
      def format_sql(sql, **opts)
        SQLFormat.check_options!(opts)
        SQLFormat.format(sql, **{ dialect: SQLFormat.dialect_for(database_type) }.merge(sqlformat_options, opts))
      end
    end

    module DatasetMethods
      # The dataset's SQL (Dataset#sql), formatted.
      def formatted_sql(**opts)
        if db.respond_to?(:format_sql)
          db.format_sql(sql, **opts)
        else
          SQLFormat.check_options!(opts)
          SQLFormat.format(sql, **{ dialect: SQLFormat.dialect_for(db.database_type) }.merge(opts))
        end
      end
    end
  end

  # Dataset first: Dataset.register_extension also registers a Database extension of the
  # same name (one that only extends datasets), so the Database registration must come
  # last to win.
  Dataset.register_extension(:sqlformat, SQLFormat::DatasetMethods)
  Database.register_extension(:sqlformat, SQLFormat::DatabaseMethods)
end
