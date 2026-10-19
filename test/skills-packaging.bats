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
