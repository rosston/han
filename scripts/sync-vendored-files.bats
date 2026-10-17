#!/usr/bin/env bats
#
# Tests for scripts/sync-vendored-files.sh. They run the script against a
# small fixture repo that mirrors Han's layout: han-core owns the canonical
# rule, one package carries a vendored copy, and one skill folder links the
# rule from its SKILL.md. A few tests run against the real repository to pin
# the canonical map itself.

SCRIPT="$BATS_TEST_DIRNAME/sync-vendored-files.sh"

make_fixture() {
  local root="$1"
  mkdir -p "$root/han-core/references" "$root/han-coding/references" \
    "$root/han-coding/skills/demo"
  printf 'CANONICAL CONFIG RULE\n' >"$root/han-core/references/config-rule.md"
  printf 'CANONICAL CONFIG RULE\n' >"$root/han-coding/references/config-rule.md"
}

@test "list prints package rows and link-derived skill rows, tab-separated, repo-relative, sorted, no header" {
  fixture="$BATS_TEST_TMPDIR/repo"
  make_fixture "$fixture"
  printf 'See [config-rule.md](../../references/config-rule.md) again [rule](../../references/config-rule.md).\n' \
    >"$fixture/han-coding/skills/demo/SKILL.md"
  cd "$fixture"
  run bash "$SCRIPT" --list
  [ "$status" -eq 0 ]
  expected=$(printf 'han-core/references/config-rule.md\than-coding/references/config-rule.md\nhan-core/references/config-rule.md\than-coding/skills/demo/references/config-rule.md\n')
  [ "$output" = "$expected" ]
}

@test "links inside fenced code blocks and inline code spans produce no rows" {
  fixture="$BATS_TEST_TMPDIR/repo"
  make_fixture "$fixture"
  {
    printf 'Real link [config-rule.md](../../references/config-rule.md).\n'
    printf '```\n'
    printf 'Fenced [evidence-rule.md](../../references/evidence-rule.md)\n'
    printf '```\n'
    printf 'Inline code `[yagni-rule.md](../../references/yagni-rule.md)` is not a link.\n'
  } >"$fixture/han-coding/skills/demo/SKILL.md"
  cd "$fixture"
  run bash "$SCRIPT" --list
  [ "$status" -eq 0 ]
  case "$output" in
    *evidence-rule.md* | *yagni-rule.md*)
      printf 'code-span link leaked:\n%s\n' "$output" >&2
      false
      ;;
  esac
  printf '%s\n' "$output" | grep -Fq "han-coding/skills/demo/references/config-rule.md"
}

@test "sync places every missing managed copy byte-identical, and a second run changes nothing" {
  fixture="$BATS_TEST_TMPDIR/repo"
  make_fixture "$fixture"
  printf 'See [config-rule.md](../../references/config-rule.md).\n' \
    >"$fixture/han-coding/skills/demo/SKILL.md"
  cd "$fixture"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  cmp -s han-core/references/config-rule.md han-coding/skills/demo/references/config-rule.md
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  cmp -s han-core/references/config-rule.md han-coding/skills/demo/references/config-rule.md
}

@test "sync refuses an existing destination that differs from its canonical source" {
  fixture="$BATS_TEST_TMPDIR/repo"
  make_fixture "$fixture"
  printf 'See [config-rule.md](../../references/config-rule.md).\n' \
    >"$fixture/han-coding/skills/demo/SKILL.md"
  mkdir -p "$fixture/han-coding/skills/demo/references"
  printf 'HAND-EDITED VENDORED COPY\n' >"$fixture/han-coding/skills/demo/references/config-rule.md"
  cd "$fixture"
  run bash "$SCRIPT"
  [ "$status" -ne 0 ]
  printf '%s\n' "$output" | grep -Fq 'han-coding/skills/demo/references/config-rule.md'
  # the drifted copy must be left exactly as found, for hand resolution
  [ "$(cat han-coding/skills/demo/references/config-rule.md)" = "HAND-EDITED VENDORED COPY" ]
}

@test "list carries the explicit destination rows for the path-string references" {
  cd "$BATS_TEST_DIRNAME/.."
  run bash "$SCRIPT" --list
  [ "$status" -eq 0 ]
  printf '%s\n' "$output" | grep -Fq \
    "han-communication/references/readability-rule.md	han-communication/skills/readability-guidance/references/readability-rule.md"
  printf '%s\n' "$output" | grep -Fq \
    "han-communication/references/writing-voice.md	han-communication/skills/readability-guidance/references/writing-voice.md"
  printf '%s\n' "$output" | grep -Fq \
    "han-communication/references/explanation-rule.md	han-communication/skills/explanation-guidance/references/explanation-rule.md"
}

@test "list vendors the guidance corpus tree into both builder skills" {
  cd "$BATS_TEST_DIRNAME/.."
  run bash "$SCRIPT" --list
  [ "$status" -eq 0 ]
  printf '%s\n' "$output" | grep -Fq \
    "han-plugin-builder/skills/guidance/references/skill-building-guidance/naming-conventions.md	han-plugin-builder/skills/skill-builder/references/skill-building-guidance/naming-conventions.md"
  printf '%s\n' "$output" | grep -Fq \
    "han-plugin-builder/skills/guidance/references/agent-building-guidelines/graceful-degradation.md	han-plugin-builder/skills/agent-builder/references/agent-building-guidelines/graceful-degradation.md"
  printf '%s\n' "$output" | grep -Fq \
    "han-plugin-builder/skills/guidance/references/plugin-entity-taxonomy.md	han-plugin-builder/skills/skill-builder/references/plugin-entity-taxonomy.md"
  # every corpus file gets one destination row per builder
  corpus_files=$(find han-plugin-builder/skills/guidance/references -type f | wc -l | tr -d ' ')
  corpus=$(printf '%s\n' "$output" | grep -c \
    "han-plugin-builder/skills/guidance/references/.*han-plugin-builder/skills/.*/references/" || true)
  [ "$corpus" -eq $((corpus_files * 2)) ]
}
