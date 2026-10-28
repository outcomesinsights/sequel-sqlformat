# frozen_string_literal: true

require "test_helper"

class FormatTest < Minitest::Test
  # Removes all whitespace, so two strings compare equal when the formatter
  # changed only layout. Used with uppercase: nil, which keeps keyword case.
  def squeeze(sql) = sql.gsub(/\s+/, "")

  def test_formats_with_the_crate_defaults
    assert_equal <<~SQL.chomp, Sequel::SQLFormat.format("select a, b from t where a = 1")
      select
        a,
        b
      from
        t
      where
        a = 1
    SQL
  end

  def test_uppercase_true_uppercases_keywords
    assert_equal "SELECT\n  a\nFROM\n  t", Sequel::SQLFormat.format("select a from t", uppercase: true)
  end

  def test_indent_option
    assert_equal "select\n    a\nfrom\n    t", Sequel::SQLFormat.format("select a from t", indent: 4)
  end

  def test_uppercase_false_lowercases_keywords
    assert_equal "select\n  a\nfrom\n  t", Sequel::SQLFormat.format("SELECT a FROM t", indent: 2, uppercase: false)
  end

  def test_uppercase_nil_keeps_keyword_case
    assert_equal "Select\n  a\nfRoM\n  t", Sequel::SQLFormat.format("Select a fRoM t", indent: 2, uppercase: nil)
  end

  def test_separates_statements_with_lines_between_queries
    out = Sequel::SQLFormat.format("select 1; select 2;", uppercase: true, lines_between_queries: 1)
    assert_equal "SELECT\n  1;\nSELECT\n  2;", out
  end

  def test_keeps_postgres_casts_and_quoted_identifiers
    sql = %(SELECT CAST("x" AS date)::text AS "Label", 'it''s' FROM "scratch"."t")
    assert_equal squeeze(sql), squeeze(Sequel::SQLFormat.format(sql, uppercase: nil, dialect: :postgresql))
  end

  def test_keeps_duckdb_interval_syntax
    sql = %(SELECT * FROM "l" WHERE ("l"."d" > CAST(("r"."e" + INTERVAL 7 DAY) AS date)))
    out = Sequel::SQLFormat.format(sql, uppercase: nil)
    assert_includes out, "INTERVAL 7 DAY"
    assert_equal squeeze(sql), squeeze(out)
  end

  def test_keeps_spark_backtick_identifiers
    sql = "SELECT `a`.`b` AS `c` FROM `db`.`t` AS `a`"
    assert_equal squeeze(sql), squeeze(Sequel::SQLFormat.format(sql, uppercase: nil))
  end

  def test_keeps_non_ascii_text_in_string_literals
    out = Sequel::SQLFormat.format("select 'café ✓' as x", uppercase: true)
    assert_includes out, "'café ✓'"
    assert_equal Encoding::UTF_8, out.encoding
  end

  def test_formatting_twice_gives_the_same_result
    once = Sequel::SQLFormat.format("select a, count(*) from t group by a having count(*) > 1 order by a", uppercase: true)
    assert_equal once, Sequel::SQLFormat.format(once)
  end

  def test_rejects_an_unknown_dialect
    error = assert_raises(ArgumentError) { Sequel::SQLFormat.format("select 1", dialect: :oracle) }
    assert_match(/unknown dialect/, error.message)
  end

  def test_rejects_a_non_string
    assert_raises(TypeError) { Sequel::SQLFormat.format(nil) }
  end

  def test_rejects_bad_option_values
    assert_raises(ArgumentError) { Sequel::SQLFormat.format("select 1", indent: -1) }
    assert_raises(ArgumentError) { Sequel::SQLFormat.format("select 1", lines_between_queries: 256) }
    assert_raises(ArgumentError) { Sequel::SQLFormat.format("select 1", uppercase: "yes") }
  end
end
