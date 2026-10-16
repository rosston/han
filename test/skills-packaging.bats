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
