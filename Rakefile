# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"
require "rb_sys/extensiontask"

Minitest::TestTask.create

GEMSPEC = Gem::Specification.load("sequel-sqlformat.gemspec")

# The platforms that get a precompiled gem (release.yml builds each one with
# oxidize-rb's cross-gem action). Every other platform installs the source gem,
# which needs a Rust toolchain.
CROSS_PLATFORMS = %w[x86_64-linux aarch64-linux x86_64-darwin arm64-darwin].freeze

RbSys::ExtensionTask.new("sequel_sqlformat", GEMSPEC) do |ext|
  ext.lib_dir = "lib/sequel/sqlformat"
  ext.cross_compile = true
  ext.cross_platform = CROSS_PLATFORMS
  # A precompiled gem builds nothing at install, so it needs no rb_sys.
  ext.cross_compiling do |spec|
    spec.dependencies.reject! { |dep| dep.name == "rb_sys" }
  end
end

task default: %i[compile test]
