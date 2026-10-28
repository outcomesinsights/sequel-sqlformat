# sequel-sqlformat

A [Sequel](https://sequel.jeremyevans.net/) extension that formats SQL for reading. It adds
`Dataset#formatted_sql` and `Database#format_sql`. Formatting runs inside the Ruby process,
through a native extension built with [magnus](https://github.com/matsadler/magnus) that wraps
the Rust [`sqlformat`](https://crates.io/crates/sqlformat) crate. No external process starts,
so formatting many statements costs milliseconds, not seconds.

```ruby
DB.extension :sqlformat

DB[:items].where(id: 1).formatted_sql(uppercase: true)
# SELECT
#   *
# FROM
#   "items"
# WHERE
#   ("id" = 1)

DB.format_sql("select a, b from t where a = 1")   # any SQL string
```

To format one dataset only, load the extension into it: `DB[:items].extension(:sqlformat)`.

Without a database:

```ruby
require "sequel/sqlformat"

Sequel::SQLFormat.format("select a from t", dialect: :postgresql)
```

## Options

| Option                  | Default    | Meaning                                                                           |
| ----------------------- | ---------- | --------------------------------------------------------------------------------- |
| `indent`                | `2`        | Spaces for each indentation level (0 to 255).                                     |
| `uppercase`             | `nil`      | `true` uppercases keywords, `false` lowercases them, `nil` keeps them.            |
| `lines_between_queries` | `1`        | Line breaks after each statement (0 to 255).                                      |
| `dialect`               | `:generic` | `:postgresql` adds array syntax. `:sqlserver` adds `[brackets]` and `@variables`. |

The defaults are the crate's defaults. Through the extension, the dialect comes from the
database type: `:postgresql` for PostgreSQL, `:sqlserver` for Microsoft SQL Server, and
`:generic` for every other database.

Set options for a database when you connect, or before you freeze it, or for one call:

```ruby
DB = Sequel.connect(url, sqlformat: { uppercase: true, indent: 4 })
DB.sqlformat_options = { uppercase: true }
DB[:items].formatted_sql(uppercase: false)
```

An unknown option name raises `ArgumentError`.

## What it does and does not do

- The crate splits SQL into tokens and does not parse it. It accepts any dialect, including
  DuckDB and Spark SQL, and it never fails on syntax that it does not know.
- It changes only whitespace and, with `uppercase: true` or `false`, the case of keywords.
- With `uppercase: true` or `false`, an unquoted identifier that is also a keyword (for
  example `status`) changes case too. Sequel quotes identifiers by default, so this matters
  only for SQL that you write yourself.

## Installation

Precompiled gems exist for x86_64 and ARM64 Linux, and for Intel and Apple Silicon macOS,
for Ruby 3.3, 3.4 and 4.0. They need no Rust. Every other platform builds the source gem,
which needs a Rust toolchain (rustc 1.84 or later) and libclang.

## Development

```sh
just setup   # tools, bundle and the git hooks
just test    # compile the extension and run the tests
just ci      # everything CI runs
```

## License

MIT. The `sqlformat` crate is MIT OR Apache-2.0.
