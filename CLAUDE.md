# sequel-sqlformat

## Quick Reference

- A Sequel extension (`DB.extension :sqlformat`) that adds `Database#format_sql` and `Dataset#formatted_sql`. A Rust native extension (magnus + rb-sys) wraps the `sqlformat` crate. `Sequel::SQLFormat.format(sql, indent:, uppercase:, lines_between_queries:, dialect:)` works with no database. Its defaults are the crate's defaults.
- Layout: `ext/sequel_sqlformat/src/lib.rs` (the binding, `Sequel::SQLFormat.native_format`), `lib/sequel/sqlformat.rb` (option checks, defaults, dialect mapping), `lib/sequel/extensions/sqlformat.rb` (the Sequel extension), `test/` (minitest, Sequel mock databases).
- Setup: `just setup` (mise tools, bundle, beads, and the tracked hooks). Building needs Rust (`rust-toolchain.toml`) and libclang.
- Test: `just test` (compiles, then runs minitest). Lint: `just lint` (rubocop, cargo fmt, clippy, shellcheck, zizmor, cog). Format: `just fmt`.
- Local CI gate: `just ci` = fmt-check, lint, hygiene, test and `package-check`. `package-check` installs the built source gem into an empty GEM_HOME and formats SQL with it.

## Git hooks

The hooks follow gator's githooks standard. They are tracked in `.githooks/`, and `just setup` arms a checkout with `git config core.hooksPath .githooks`. Never edit the files in `.githooks/`; they are copies of gator's `standard/githooks/`.

- `pre-commit`: `just pre-commit` on the working tree. If fmt-check reformats anything, re-stage and commit again.
- `pre-push`: `just ci` at each pushed commit, in a gate worktree under `~/.cache/gator-gate/`, then the beads publish.
- Never skip the hooks with `--no-verify`.

## Releasing

Releases are tag-based. A pushed `v*` tag runs `.github/workflows/release.yml`. It builds a source gem and a precompiled gem for each platform in the Rakefile's `CROSS_PLATFORMS`, installs each precompiled gem on its own platform for Ruby 3.3, 3.4 and 4.0, and publishes all of them through RubyGems trusted publishing.

1. Run `git cliff --bumped-version` for the next version. Bump `VERSION` in `lib/sequel/sqlformat/version.rb`, run `bundle install`, and move the `[Unreleased]` entries in `CHANGELOG.md` under the new version.
2. Land that commit on `main` and wait for the `CI` workflow to pass on the push.
3. Tag that commit and push the tag: `git tag v0.1.0 && git push origin v0.1.0`.

The workflow refuses to publish unless the tag is `v` + `Sequel::SQLFormat::VERSION`, the commit is on `main`, and a push-to-`main` run of `ci.yml` succeeded on that exact commit.

One-time setup, done by a repository owner: register the trusted publisher on rubygems.org (owner `outcomesinsights`, repository `sequel-sqlformat`, workflow `release.yml`, environment `release`). For a gem that is not on rubygems.org yet, this is a "pending trusted publisher". In the GitHub `release` environment, allow deployments only from `v*` tags.

## Gotchas

- The crate works on tokens and does not parse SQL. It cannot fail on unknown syntax, and it changes only whitespace and, with `uppercase: true` or `false`, the case of keywords.
- With `uppercase: true` or `false`, an unquoted identifier that is also a keyword changes case too.
- A precompiled gem keeps one library per Ruby minor version under `lib/sequel/sqlformat/<major.minor>/`. `lib/sequel/sqlformat.rb` loads that first and falls back to `lib/sequel/sqlformat/sequel_sqlformat.so` from a source build.
- `Dataset.register_extension` also registers a Database extension of the same name. The extension file therefore registers the Dataset extension first and the Database extension last, so the Database one wins.
