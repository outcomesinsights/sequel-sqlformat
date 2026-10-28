# frozen_string_literal: true

require "test_helper"

class ExtensionTest < Minitest::Test
  def db(host = :postgres, **opts)
    Sequel.mock(host: host, **opts).extension(:sqlformat)
  end

  def test_dataset_formatted_sql
    assert_equal %(SELECT\n  *\nFROM\n  "items"\nWHERE\n  ("id" = 1)), db[:items].where(id: 1).formatted_sql(uppercase: true)
  end

  def test_formatted_sql_formats_the_same_sql_as_dataset_sql
    ds = db[:items].select(:a, :b).where(Sequel[:a] > 1).order(:b).limit(5)
    assert_equal ds.sql.gsub(/\s+/, ""), ds.formatted_sql.gsub(/\s+/, "")
  end

  def test_format_sql_formats_any_string
    assert_equal "select\n  a\nfrom\n  t", db.format_sql("select a from t")
  end

  def test_dialect_comes_from_the_database_type
    assert_equal :postgresql, Sequel::SQLFormat.dialect_for(db(:postgres).database_type)
    assert_equal :sqlserver, Sequel::SQLFormat.dialect_for(db(:mssql).database_type)
    assert_equal :generic, Sequel::SQLFormat.dialect_for(db(:sqlite).database_type)
  end

  # The PostgreSQL mode knows array brackets; the generic mode does not.
  def test_postgres_database_uses_the_postgresql_mode
    sql = "select a[1] from t"
    assert_equal Sequel::SQLFormat.format(sql, dialect: :postgresql), db(:postgres).format_sql(sql)
  end

  # The SQL Server mode knows [bracketed identifiers] and @variables.
  def test_mssql_database_uses_the_sqlserver_mode
    sql = "select [a b] from t where x = @v"
    assert_equal Sequel::SQLFormat.format(sql, dialect: :sqlserver), db(:mssql).format_sql(sql)
  end

  def test_options_from_the_connect_hash
    d = db(sqlformat: { uppercase: true, indent: 4 })
    assert_equal "SELECT\n    a\nFROM\n    t", d.format_sql("select a from t")
  end

  def test_options_set_on_the_database
    d = db
    d.sqlformat_options = { uppercase: true }
    assert_equal "SELECT\n  a\nFROM\n  t", d.format_sql("select a from t")
  end

  def test_per_call_options_win_over_database_options
    d = db(sqlformat: { uppercase: true })
    assert_equal "select\n  a\nfrom\n  t", d.format_sql("SELECT a FROM t", uppercase: false)
  end

  def test_an_explicit_dialect_wins_over_the_database_type
    assert_equal Sequel::SQLFormat.format("select [a]", dialect: :sqlserver), db(:postgres).format_sql("select [a]", dialect: :sqlserver)
  end

  def test_dataset_extension_without_the_database_extension
    plain = Sequel.mock(host: :postgres)
    refute_respond_to plain, :format_sql
    out = plain[:items].extension(:sqlformat).formatted_sql(uppercase: true)
    assert_equal %(SELECT\n  *\nFROM\n  "items"), out
  end

  def test_works_on_a_frozen_database
    d = db(sqlformat: { uppercase: true })
    d.freeze
    assert_equal %(SELECT\n  *\nFROM\n  "items"), d[:items].formatted_sql
  end

  def test_rejects_unknown_option_keys
    assert_raises(ArgumentError) { db(sqlformat: { upcase: true }) }
    assert_raises(ArgumentError) { db.format_sql("select 1", indnet: 2) }
    assert_raises(ArgumentError) { db.sqlformat_options = { lines: 2 } }
  end

  def test_rejects_a_non_hash_option_set
    assert_raises(TypeError) { db.sqlformat_options = [ :uppercase ] }
  end

  def test_database_options_are_frozen
    d = db(sqlformat: { uppercase: true })
    assert_predicate d.sqlformat_options, :frozen?
  end
end
