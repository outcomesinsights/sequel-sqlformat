# Changelog

## [Unreleased]

### Added

- The `sqlformat` Sequel extension: `Database#format_sql`, `Dataset#formatted_sql`, and `sqlformat_options` on a database or in the connect hash. The dialect comes from the database type.
- `Sequel::SQLFormat.format(sql, indent:, uppercase:, lines_between_queries:, dialect:)` formats SQL with the Rust `sqlformat` crate 0.5, with no database. The defaults are the crate's defaults.
