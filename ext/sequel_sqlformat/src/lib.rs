//! Ruby bindings for the `sqlformat` crate.
//!
//! The Ruby side (lib/sequel/sqlformat.rb) validates and defaults the options, then
//! calls `Sequel::SQLFormat.native_format` with every argument given.

use magnus::{function, prelude::*, Error, Ruby};
use sqlformat::{Dialect, FormatOptions, Indent, QueryParams};

fn dialect_from(ruby: &Ruby, name: &str) -> Result<Dialect, Error> {
    match name {
        "generic" => Ok(Dialect::Generic),
        "postgresql" => Ok(Dialect::PostgreSql),
        "sqlserver" => Ok(Dialect::SQLServer),
        other => Err(Error::new(
            ruby.exception_arg_error(),
            format!("unknown dialect {other:?}; expected generic, postgresql or sqlserver"),
        )),
    }
}

fn native_format(
    ruby: &Ruby,
    sql: String,
    indent: u8,
    uppercase: Option<bool>,
    lines_between_queries: u8,
    dialect: String,
) -> Result<String, Error> {
    let options = FormatOptions {
        indent: Indent::Spaces(indent),
        uppercase,
        lines_between_queries,
        dialect: dialect_from(ruby, &dialect)?,
        ..FormatOptions::default()
    };
    Ok(sqlformat::format(&sql, &QueryParams::None, &options))
}

#[magnus::init]
fn init(ruby: &Ruby) -> Result<(), Error> {
    let module = ruby.define_module("Sequel")?.define_module("SQLFormat")?;
    module.define_singleton_method("native_format", function!(native_format, 5))?;
    Ok(())
}
