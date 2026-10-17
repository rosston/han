#!/usr/bin/env bats
#
# Packaging guard for the `npx skills` compatibility contract. Grows with the
# work items in docs/plans/npx-skills/compatibility/work-items.md; W-9 lands
# the full nine assertions. Portability constraints inherited from
# test/codex-packaging.bats: bash 3.2 (no mapfile, declare -A, or globstar),
# grep one named file at a time, never -r. The guard never invokes the
# `npx skills` CLI.

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

# Reads `--list` rows (canonical_path<TAB>destination_path) on stdin. Fails on
# the first destination that exists and differs from its canonical source, and
# fails if no destination existed to compare — a check that compared nothing
# would pass vacuously. Missing destinations are the W-3 vendoring's absence,
# which this W-2 seed does not claim.
check_vendored_identity() {
  local src dst compared=0
  while IFS="$(printf '\t')" read -r src dst; do
    [ -e "$dst" ] || continue
    compared=$((compared + 1))
    if ! cmp -s "$src" "$dst"; then
      printf 'differs from canonical: %s\n' "$dst" >&2
      return 1
    fi
  done
  [ "$compared" -gt 0 ]
}

@test "every managed vendored copy that exists on disk is byte-identical to its canonical source" {
  bash scripts/sync-vendored-files.sh --list | check_vendored_identity
}

@test "the identity check fails on a drifted vendored copy it builds itself" {
  root="$BATS_TEST_TMPDIR/drift"
  mkdir -p "$root/han-core/references" "$root/han-coding/references"
  printf 'CANONICAL CONFIG RULE\n' >"$root/han-core/references/config-rule.md"
  printf 'DRIFTED COPY\n' >"$root/han-coding/references/config-rule.md"
  if (
    cd "$root"
    bash "$BATS_TEST_DIRNAME/../scripts/sync-vendored-files.sh" --list | check_vendored_identity
  ); then
    echo "identity check passed on a drifted repository" >&2
    false
  fi
}
