#!/usr/bin/env bash
#
# scripts/sync-vendored-files.sh — keep vendored copies of shared rule files
# identical to their canonical owners. Run from the Han repository root.
#
# The canonical map below names one canonical owner per shared rule file.
# Canonical owners: han-core owns config-rule.md, evidence-rule.md,
# yagni-rule.md, and collaborative-stop-rule.md; han-communication owns
# readability-rule.md, writing-voice.md, and explanation-rule.md;
# han-planning owns planning-boundary-rule.md, scope-justification-rule.md,
# operator-escalation-rule.md, contract-pinning-rule.md, and
# synthesis-failure-rule.md.
#
# Usage:
#   scripts/sync-vendored-files.sh          sync every managed copy: create
#                                           missing destinations; an existing
#                                           destination that differs from its
#                                           canonical is refused, never
#                                           overwritten (resolve by hand)
#   scripts/sync-vendored-files.sh --list   print canonical_path<TAB>destination_path,
#                                           repo-relative, LF, sorted, no header

set -euo pipefail

# One line per shared rule file: "<basename> <canonical_path>".
RULES="config-rule.md han-core/references/config-rule.md
evidence-rule.md han-core/references/evidence-rule.md
yagni-rule.md han-core/references/yagni-rule.md
collaborative-stop-rule.md han-core/references/collaborative-stop-rule.md
readability-rule.md han-communication/references/readability-rule.md
writing-voice.md han-communication/references/writing-voice.md
explanation-rule.md han-communication/references/explanation-rule.md
planning-boundary-rule.md han-planning/references/planning-boundary-rule.md
scope-justification-rule.md han-planning/references/scope-justification-rule.md
operator-escalation-rule.md han-planning/references/operator-escalation-rule.md
contract-pinning-rule.md han-planning/references/contract-pinning-rule.md
synthesis-failure-rule.md han-planning/references/synthesis-failure-rule.md"

# Package-level vendored copies: every han-*/references/<rule> that is not the
# canonical file itself.
emit_package_rows() {
  local base canon f
  while IFS=' ' read -r base canon; do
    [ -n "$base" ] || continue
    for f in han-*/references/"$base"; do
      [ -f "$f" ] || continue
      [ "$f" = "$canon" ] && continue
      printf '%s\t%s\n' "$canon" "$f"
    done
  done <<EOF
$RULES
EOF
}

# Skill-level vendoring derived from links: every markdown link in a skill
# folder whose target basename is a mapped rule places a copy at
# {skill}/references/<basename>.
emit_skill_rows() {
  local dir file rules_escaped
  rules_escaped=${RULES//$'\n'/\\n}
  for dir in han-*/skills/*/ .claude/skills/*/; do
    [ -d "$dir" ] || continue
    while IFS= read -r file; do
      awk -v map="$rules_escaped" -v skdir="${dir%/}" '
        BEGIN {
          n = split(map, pair, "\n")
          for (i = 1; i <= n; i++) {
            if (pair[i] == "") continue
            p = index(pair[i], " ")
            canon[substr(pair[i], 1, p - 1)] = substr(pair[i], p + 1)
          }
        }
        function emit_links(s,   t, m, parts, b) {
          while (match(s, /\]\([^)]+\)/)) {
            t = substr(s, RSTART + 2, RLENGTH - 3)
            sub(/#.*/, "", t)
            m = split(t, parts, "/")
            b = parts[m]
            if (b in canon) print canon[b] "\t" skdir "/references/" b
            s = substr(s, RSTART + RLENGTH)
          }
        }
        /^[ \t]*(```|~~~)/ { fence = !fence; next }
        fence { next }
        {
          # Drop inline code spans: an odd-length backtick run opens or closes
          # a span; even-length runs are literal backticks.
          line = $0; out = ""; code = 0; i = 1; len = length(line)
          while (i <= len) {
            c = substr(line, i, 1)
            if (c == "`") {
              j = i
              while (j <= len && substr(line, j, 1) == "`") j++
              if ((j - i) % 2 == 1) code = !code
              i = j
              continue
            }
            if (!code) out = out c
            i++
          }
          emit_links(out)
        }
      ' "$file"
    done <<EOF
$(find "$dir" -name '*.md' -type f)
EOF
  done
}

# Explicit destination rows for path-string references that are not markdown
# links: the rules the two inline guidance skills read by path, and the whole
# guidance corpus tree that skill-builder and agent-builder read by path.
emit_explicit_rows() {
  local pair src dst rel dir skill_name
  for pair in \
    "han-communication/references/readability-rule.md han-communication/skills/readability-guidance/references/readability-rule.md" \
    "han-communication/references/writing-voice.md han-communication/skills/readability-guidance/references/writing-voice.md" \
    "han-communication/references/explanation-rule.md han-communication/skills/explanation-guidance/references/explanation-rule.md"; do
    src=${pair%% *}
    dst=${pair#* }
    [ -f "$src" ] || continue
    printf '%s\t%s\n' "$src" "$dst"
  done
  dir=han-plugin-builder/skills/guidance/references
  [ -d "$dir" ] || return 0
  while IFS= read -r src; do
    rel=${src#"$dir"/}
    for skill_name in skill-builder agent-builder; do
      printf '%s\t%s\n' "$src" "han-plugin-builder/skills/$skill_name/references/$rel"
    done
  done <<EOF
$(find "$dir" -type f)
EOF
}

emit_rows() {
  emit_package_rows
  emit_skill_rows
  emit_explicit_rows
}

list_file=$(mktemp)
trap 'rm -f "$list_file"' EXIT

# LC_ALL=C pins byte ordering so the list is identical on macOS and CI Linux.
emit_rows | LC_ALL=C sort -u >"$list_file"

if [ "${1:-}" = "--list" ]; then
  cat "$list_file"
  exit 0
fi

# Sync mode: place missing managed copies. An existing destination that
# differs from its canonical is refused, never overwritten: resolve the drift
# by hand, then re-run.
refused=0
while IFS=$(printf '\t') read -r src dst; do
  [ -n "$src" ] || continue
  if [ -e "$dst" ]; then
    cmp -s "$src" "$dst" && continue
    printf 'refusing to overwrite %s: it differs from canonical %s\n' "$dst" "$src" >&2
    refused=1
    continue
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
done <"$list_file"

exit "$refused"
