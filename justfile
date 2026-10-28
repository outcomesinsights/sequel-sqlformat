# Recipes follow gator's standard (githooks, treefmt, mise). The hooks in .githooks/
# run `pre-commit` at each commit and `ci` at each pushed commit.

# Install the pinned tools and the bundle, then arm the tracked hooks (.githooks). bd
# bootstrap, never bd init: in a clone that already has .beads, init re-points the hooks and commits.
setup:
    mise install
    bundle install
    @if [ -d .beads ] && [ ! -d .beads/embeddeddolt ] && command -v bd >/dev/null 2>&1; then bd bootstrap; fi
    @if [ -d .githooks ]; then git config core.hooksPath .githooks; fi

# Build the native extension into lib/sequel/sqlformat/.
compile:
    bundle exec rake compile

# Build the extension, then run the minitest suite.
test: compile
    bundle exec rake test

# Report what a formatter cannot fix: cops, Rust lints, shell scripts, workflow audits
# and commit subjects. cog checks every commit since the last v* tag, or the whole
# history before the first tag.
lint:
    bundle exec rubocop
    cargo fmt --all --check
    cargo clippy --all-targets --locked -- -D warnings
    git ls-files -z '*.sh' '*.bash' | xargs -0 -r shellcheck -S warning
    zizmor --offline --config .github/zizmor.yml .
    tag="$(git describe --tags --abbrev=0 --match 'v*' 2>/dev/null || true)"; if ! git rev-parse -q --verify HEAD >/dev/null; then echo "cog: no commits yet"; elif [ -n "$tag" ]; then cog check --ignore-merge-commits "$tag..HEAD"; else cog check --ignore-merge-commits; fi

# Rewrite files to canonical format. Run deliberately; never from a hook.
fmt:
    treefmt
    cargo fmt --all

# Apply canonical format and fail if anything was out of shape. treefmt formats the tree
# and then exits 1, so a failed commit has already fixed the files: re-stage and commit.
fmt-check:
    treefmt --fail-on-change

# Check for conflict markers, malformed YAML/JSON/TOML, and workflow defects.
hygiene:
    #!/usr/bin/env bash
    set -uo pipefail
    rc=0
    bad=$(git ls-files | xargs -r grep -IlE '^(<{7}|={7}|>{7})( |$)' 2>/dev/null || true)
    [ -n "$bad" ] && { echo "merge conflict markers:"; printf '%s\n' "$bad" | sed 's/^/  /'; rc=1; }
    for f in $(git ls-files '*.yml' '*.yaml'); do
      python3 -c 'import yaml,sys; yaml.safe_load(open(sys.argv[1]))' "$f" 2>/dev/null \
        || { echo "invalid YAML: $f"; rc=1; }
    done
    for f in $(git ls-files '*.json'); do
      jq empty "$f" 2>/dev/null || { echo "invalid JSON: $f"; rc=1; }
    done
    # actionlint type-checks the workflows and runs shellcheck over every `run:` block.
    actionlint -no-color -oneline || rc=1
    exit $rc

# Build the source gem, install it with only its runtime dependencies into an empty
# GEM_HOME, and format SQL through the Sequel extension from the installed copy. This
# tests the artifact that ships: the gemspec's file list, extconf.rb and the Cargo files.
package-check:
    #!/usr/bin/env bash
    set -euo pipefail
    work=$(mktemp -d)
    trap 'rm -rf "$work"' EXIT
    gem build sequel-sqlformat.gemspec --output "$work/sequel-sqlformat.gem"
    export GEM_HOME="$work/home" GEM_PATH="$work/home"
    gem install --no-document "$work/sequel-sqlformat.gem"
    cd "$work"
    ruby -e '
      require "sequel"
      db = Sequel.mock(host: :postgres).extension(:sqlformat)
      dir = Gem.loaded_specs["sequel-sqlformat"].gem_dir
      abort "loaded #{dir}, not the installed gem" unless dir.start_with?(ENV.fetch("GEM_HOME"))
      out = db[:t].formatted_sql(uppercase: true)
      abort "unexpected output: #{out.inspect}" unless out == "SELECT\n  *\nFROM\n  \"t\""
      puts "installed gem at #{dir} formats SQL through the Sequel extension"'

# Verify the seeds store is plausible. Skips when seeds is absent: this is a deliberation
# store, not shipped code. --gate honours SEEDS_GATE_CONFIRM=1 for an intended rewrite.
seeds-check:
    @command -v seeds >/dev/null 2>&1 || exit 0; seeds check --gate

# What runs before every commit. Must stay fast.
pre-commit: fmt-check lint hygiene seeds-check

# The full local equivalent of CI (.github/workflows/ci.yml). The push gate runs it at
# each pushed commit. ci.yml's jobs run these same recipes; change one and change the other.
ci: fmt-check lint hygiene test package-check

# Kept for checkouts whose old hooks call it by name (gator's transition rule).
pre-push: ci
