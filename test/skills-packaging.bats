#!/usr/bin/env bats
#
# Packaging guard for the `npx skills` compatibility contract. Grows with the
# work items in docs/plans/npx-skills/compatibility/work-items.md; W-9 lands
# the full nine assertions. Portability constraints inherited from
# test/codex-packaging.bats: bash 3.2 (no mapfile, declare -A, or globstar),
# grep one named file at a time, never -r. The guard never invokes the
# `npx skills` CLI.

REPO_ROOT="${BATS_TEST_DIRNAME}/.."

# True when the SKILL.md's frontmatter ends with the byte-exact CLI
# internal-skill marker block: `metadata:` followed by `  internal: true`,
# appended as the last frontmatter key (implementation decision D-12).
marker_is_last_frontmatter_key() {
  local file="$1"
  [ -f "$file" ] || return 1
  head -n 1 "$file" | grep -qx -- '---' || return 1
  local fm last_two
  fm=$(awk 'NR > 1 && /^---/ { exit } NR > 1' "$file")
  last_two=$(printf '%s\n' "$fm" | tail -n 2)
  [ "$last_two" = "$(printf 'metadata:\n  internal: true')" ]
}

# True when no markdown link in any .md file inside a skill folder resolves to
# a path outside that folder. Shared link grammar with the sync script: every
# ](...) outside fenced code blocks and outside inline code spans; URLs,
# anchors, and absolute paths ignored; fragments stripped.
no_links_escape_skill_folders() {
  local dir file target resolved d seg bad=0
  for dir in han-*/skills/*/ .claude/skills/*/; do
    [ -d "$dir" ] || continue
    while IFS= read -r file; do
      while IFS= read -r target; do
        [ -n "$target" ] || continue
        case "$target" in
          http:*|https:*|mailto:*|/*|\#*) continue ;;
        esac
        d=$(dirname "$file")
        seg=$target
        while [ "${seg#"../"}" != "$seg" ]; do
          d=$(dirname "$d")
          seg=${seg#"../"}
        done
        resolved="$d/$seg"
        case "$resolved" in
          "${dir%"/"}/"*|"$file") : ;;
          *)
            printf 'escapes folder: %s -> %s\n' "$file" "$target" >&2
            bad=1
            ;;
        esac
      done <<EOF
$(awk '
          /^[ \t]*(```|~~~)/ { fence = !fence; next }
          fence { next }
          function strip_code(s, out, c, i, j, len, code) {
            out = ""; code = 0; i = 1; len = length(s)
            while (i <= len) {
              c = substr(s, i, 1)
              if (c == "`") {
                j = i
                while (j <= len && substr(s, j, 1) == "`") j++
                if ((j - i) % 2 == 1) code = !code
                i = j
                continue
              }
              if (!code) out = out c
              i++
            }
            return out
          }
          {
            s = strip_code($0)
            while (match(s, /\]\([^)]+\)/)) {
              t = substr(s, RSTART + 2, RLENGTH - 3)
              sub(/#.*/, "", t)
              if (t != "" && t !~ /^https?:/ && t !~ /^mailto:/ && t !~ /^\//)
                print t
              s = substr(s, RSTART + RLENGTH)
            }
          }' "$file")
EOF
    done <<EOF
$(find "$dir" -name '*.md' -type f)
EOF
  done
  [ "$bad" -eq 0 ]
}

@test "no markdown link in a skill folder resolves outside that folder" {
  no_links_escape_skill_folders
}

# Read --list rows on stdin; fail if any managed destination is absent or
# differs from its canonical source. Requires at least one row: an empty list
# would pass both clauses vacuously.
check_vendored_placement_and_identity() {
  local src dst rows=0
  while IFS="$(printf '\t')" read -r src dst; do
    rows=$((rows + 1))
    if [ ! -e "$dst" ]; then
      printf 'missing managed copy: %s\n' "$dst" >&2
      return 1
    fi
    if ! cmp -s "$src" "$dst"; then
      printf 'differs from canonical: %s\n' "$dst" >&2
      return 1
    fi
  done
  [ "$rows" -gt 0 ]
}

@test "every managed vendored copy is placed on disk and byte-identical to its canonical source" {
  bash scripts/sync-vendored-files.sh --list | check_vendored_placement_and_identity
}

# Every markdown file inside a skill folder: the SKILL.md itself plus its
# references and assets. The two `.claude` repo-maintenance skills are included
# on the same terms as assertion 2's link check, so a future plugin-root
# reference there reddens the guard too. Takes the repository root so a built
# fixture can be checked with the same function.
skill_markdown_files() {
  local dir
  for dir in "$1"/han-*/skills/*/ "$1"/.claude/skills/*/; do
    [ -d "$dir" ] || continue
    find "$dir" -name '*.md' -type f
  done
}

# Seed of release-guard assertion 4 (plan D-5), landed early by W-4 because the
# portable-configuration rewrite removes the dependency it guards. After a
# channel install there is no plugin root, so no markdown file in a skill folder
# may name `${CLAUDE_PLUGIN_ROOT}` — not in a probe, not in an allowed-tools
# grant, not in an instruction path string.
check_no_plugin_root() {
  local file bad=0 files=0
  while IFS= read -r file; do
    files=$((files + 1))
    if grep -qF -- 'CLAUDE_PLUGIN_ROOT' "$file"; then
      printf 'names the plugin root: %s\n' "$file" >&2
      bad=1
    fi
  done <<EOF
$(skill_markdown_files "$1")
EOF
  # Vacuity guard: a check that inspected nothing is not a check.
  [ "$files" -gt 0 ] || {
    printf 'no skill markdown files discovered under: %s\n' "$1" >&2
    return 1
  }
  [ "$bad" -eq 0 ]
}

@test "no markdown file in a skill folder names the plugin root" {
  check_no_plugin_root "$REPO_ROOT"
}

# shellcheck disable=SC2016
@test "the plugin-root check fails on a built fixture that names the plugin root" {
  root="$BATS_TEST_TMPDIR/proot"
  mkdir -p "$root/han-fixture/skills/demo"
  printf 'run bash "${CLAUDE_PLUGIN_ROOT}/scripts/thing.sh" from the probe\n' \
    >"$root/han-fixture/skills/demo/SKILL.md"
  if check_no_plugin_root "$root"; then
    echo "plugin-root check passed on a fixture that names the plugin root" >&2
    false
  fi
}

# The one line allowed to carry a configuration-home literal, matched byte for
# byte (spec D5, plan D-4). scripts/han-config-dir.bats is the pinner of this
# literal in the 45 plugin skills; here it is the whitelist for assertion 5, so
# a skill body may use the resolved directory but never the home path itself.
# shellcheck disable=SC2016
PINNED_LINE='- personal config directory: $CLAUDE_CONFIG_DIR when that variable is set, otherwise $HOME/.claude (the agent'\''s own configuration-directory override and its default)'

# Seed of release-guard assertion 5 (plan D-5): no configuration-home literal
# outside the pinned portable line. Hardcoded homes break skills on agents
# whose configuration home is not `~/.claude` (finding F4); the resolution the
# pinned line carries replaces every such path.
check_no_hardcoded_home() {
  local file line matches bad=0 files=0
  while IFS= read -r file; do
    files=$((files + 1))
    # The single quotes are deliberate: these are literal SKILL.md text
    # patterns, matched byte for byte, nothing inside them may expand. The
    # `|| true` keeps a file with no literal from tripping the shell's error
    # halt: absence is the passing case here, per file. The tilde is a literal
    # character of the matched text, never a home-directory expression.
    # shellcheck disable=SC2016,SC2088
    matches=$(grep -F -e '~/.claude' -e '$HOME/.claude' -e '${HOME}/.claude' "$file" 2>/dev/null || true)
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      [ "$line" = "$PINNED_LINE" ] && continue
      printf 'hardcodes the configuration home (%s): %s\n' "$file" "$line" >&2
      bad=1
    done <<EOF
$matches
EOF
  done <<EOF
$(skill_markdown_files "$1")
EOF
  # Vacuity guard: a check that inspected nothing is not a check.
  [ "$files" -gt 0 ] || {
    printf 'no skill markdown files discovered under: %s\n' "$1" >&2
    return 1
  }
  [ "$bad" -eq 0 ]
}

@test "no markdown file in a skill folder hardcodes the configuration home outside the pinned line" {
  check_no_hardcoded_home "$REPO_ROOT"
}

@test "the configuration-home check fails on a built fixture that hardcodes the home" {
  root="$BATS_TEST_TMPDIR/home"
  mkdir -p "$root/han-fixture/skills/demo"
  printf 'write the report to ~/.claude/reports/{filename}\n' \
    >"$root/han-fixture/skills/demo/SKILL.md"
  if check_no_hardcoded_home "$root"; then
    echo "configuration-home check passed on a fixture that hardcodes the home" >&2
    false
  fi
}

# Whitelist teeth, both directions: the pinned portable line may carry the
# literal (accept side) and nothing else may (reject side). Written from the
# same PINNED_LINE constant the check uses, so the fixture and the whitelist
# cannot drift apart.
@test "the configuration-home check whitelists exactly the pinned line" {
  root="$BATS_TEST_TMPDIR/whitelist"
  mkdir -p "$root/han-fixture/skills/demo/references"
  {
    printf '%s\n' "$PINNED_LINE"
    printf 'a relative path in the personal file resolves against it\n'
  } >"$root/han-fixture/skills/demo/SKILL.md"
  check_no_hardcoded_home "$root"
  # The single quotes are deliberate: this fixture line must carry the literal
  # path and backticks verbatim, exactly what the reject side of the whitelist
  # is supposed to catch.
  # shellcheck disable=SC2016
  printf 'prose naming the default: `~/.claude/.han/config.md` does not qualify\n' \
    >"$root/han-fixture/skills/demo/references/some-rule.md"
  if check_no_hardcoded_home "$root"; then
    echo "configuration-home check passed with a non-pinned literal in references/some-rule.md" >&2
    false
  fi
}

@test "han-release SKILL.md carries the byte-exact internal marker as the last frontmatter key" {
  marker_is_last_frontmatter_key .claude/skills/han-release/SKILL.md
}

@test "han-update-documentation SKILL.md carries the byte-exact internal marker as the last frontmatter key" {
  marker_is_last_frontmatter_key .claude/skills/han-update-documentation/SKILL.md
}

@test "the internal marker sits on exactly the two repo-maintenance skills in the discovery set" {
  marked=""
  for f in han-*/skills/*/SKILL.md .claude/skills/*/SKILL.md; do
    if marker_is_last_frontmatter_key "$f"; then
      marked="$marked $f"
    fi
  done
  [ "$marked" = " .claude/skills/han-release/SKILL.md .claude/skills/han-update-documentation/SKILL.md" ]
}

@test "han-release stops when run outside the Han repository, naming the repository in the stop" {
  grep -Fq 'han repo marker' .claude/skills/han-release/SKILL.md
  grep -Fq "maintains Han's own repository" .claude/skills/han-release/SKILL.md
}

@test "han-update-documentation stops when run outside the Han repository, naming the repository in the stop" {
  grep -Fq "maintains Han's own repository" .claude/skills/han-update-documentation/SKILL.md
}

@test "the identity check fails on a drifted vendored copy it builds itself" {
  root="$BATS_TEST_TMPDIR/drift"
  mkdir -p "$root/han-core/references" "$root/han-coding/references"
  printf 'CANONICAL CONFIG RULE\n' >"$root/han-core/references/config-rule.md"
  printf 'DRIFTED COPY\n' >"$root/han-coding/references/config-rule.md"
  if (
    cd "$root"
    bash "$BATS_TEST_DIRNAME/../scripts/sync-vendored-files.sh" --list | check_vendored_placement_and_identity
  ); then
    echo "identity check passed on a drifted repository" >&2
    false
  fi
}
