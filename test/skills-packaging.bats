#!/usr/bin/env bats
#
# Packaging guard for the `npx skills` compatibility contract — the nine
# assertions of plan D-5, landed alongside work items W-4 through W-9:
#   1 frontmatter name unique/non-empty/equals folder basename
#   2 links neither escape the skill folder nor dangle at missing shipped files
#   3 marketplace declarations equal the on-disk inventory (meta none, no
#     package plugin.json skills)
#   4 no CLAUDE_PLUGIN_ROOT in any skill .md
#   5 no configuration-home literal outside the pinned portable line
#   6 discovery set exactly 45 plugin skills + 2 marked internal
#   7 vendored copies byte-identical to canonical at package and skill level
#   8 README names both channels, the update command, and the internal opt-in
#   9 no CLAUDE_SKILL_DIR in any skill .md
# Every check is root-parameterized and the composite fixture at the tail
# violates all nine at once: the guard is observed failing there before the
# clean suite passes. Portability constraints inherited from
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

# Shared link grammar (same as scripts/sync-vendored-files.sh): every ](...)
# outside fenced code blocks and outside inline code spans; URLs, anchors, and
# absolute paths ignored; fragments stripped. One walker, two consumers — the
# escape check and the dangling check must never drift apart.
md_link_targets() {
  awk '
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
    }' "$1"
}

# True when no markdown link in any .md file inside a skill folder resolves to
# a path outside that folder (assertion 2, escape clause). Takes a repository
# root so fixtures run the same code.
no_links_escape_skill_folders() {
  local root="$1" dir file target resolved d seg bad=0
  for dir in "$root"/han-*/skills/*/ "$root"/.claude/skills/*/; do
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
$(md_link_targets "$file")
EOF
    done <<EOF
$(find "$dir" -name '*.md' -type f)
EOF
  done
  [ "$bad" -eq 0 ]
}

# Assertion 2, dangling clause. A skill folder ships SKILL.md, references/,
# scripts/, and assets/; a link resolving to one of those shapes must point at
# a file that exists (the F6 class: a linked rule that never got vendored).
# Two classes of links are excluded by design, not by grudge:
#  - Scaffold files: templates and assets whose content is copied into the
#    user's tree and links to artifacts that exist only after instantiation
#    (*-template.md, template.md, the work-items format doc, anything under
#    templates/ or assets/).
#  - Placeholder and destination-layout targets: {curly} / [bracket] / <angle> /
#    ... examples, and links resolving outside the shipped shapes (docs/...,
#    artifacts/..., .claude/..., skill-root siblings) — those are contracts of
#    the destination repository, not of the skill folder.
no_links_dangle_shipped_content() {
  local root="$1" dir file target resolved d seg rel base bad=0
  for dir in "$root"/han-*/skills/*/ "$root"/.claude/skills/*/; do
    [ -d "$dir" ] || continue
    while IFS= read -r file; do
      base=$(basename "$file")
      case "$file" in
        */templates/*|*/assets/*) continue ;;
      esac
      case "$base" in
        *-template.md|template.md|work-items-file-format.md) continue ;;
      esac
      while IFS= read -r target; do
        [ -n "$target" ] || continue
        case "$target" in
          http:*|https:*|mailto:*|/*|\#*) continue ;;
        esac
        case "$target" in
          *'{'*|*'['*|*'<'*|*...*) continue ;;
        esac
        d=$(dirname "$file")
        seg=$target
        while [ "${seg#"../"}" != "$seg" ]; do
          d=$(dirname "$d")
          seg=${seg#"../"}
        done
        while [ "${seg#"./"}" != "$seg" ]; do
          seg=${seg#"./"}
        done
        resolved="$d/$seg"
        rel=${resolved#"$dir"}
        case "$rel" in
          references/*|scripts/*|assets/*|SKILL.md) : ;;
          *) continue ;;
        esac
        if [ ! -e "$resolved" ]; then
          printf 'dangling shipped-content link: %s -> %s\n' "$file" "$target" >&2
          bad=1
        fi
      done <<EOF
$(md_link_targets "$file")
EOF
    done <<EOF
$(find "$dir" -name '*.md' -type f)
EOF
  done
  [ "$bad" -eq 0 ]
}

# Assertion 1: the CLI installs the folder, so the folder name is the installed
# identity; the agent-skills specification requires the frontmatter name to
# match it, names to be unique, and descriptions non-empty (inline value, or a
# folded block with content).
check_frontmatter_names() {
  local root="$1" f name base dup names=""
  for f in "$root"/han-*/skills/*/SKILL.md "$root"/.claude/skills/*/SKILL.md; do
    [ -f "$f" ] || continue
    name=$(awk '/^---/{c++; if (c > 1) exit; next} c == 1 && /^name:/{v = substr($0, 7); gsub(/"/, "", v); gsub(/[[:space:]]+$/, "", v); print v; exit}' "$f")
    base=$(basename "$(dirname "$f")")
    if [ -z "$name" ]; then
      printf 'empty or missing frontmatter name: %s\n' "$f" >&2
      return 1
    fi
    if [ "$name" != "$base" ]; then
      printf 'name does not match folder basename: %s (name=%s folder=%s)\n' "$f" "$name" "$base" >&2
      return 1
    fi
    names="$names$name
"
  done
  dup=$(printf '%s' "$names" | sort | uniq -d)
  if [ -n "$dup" ]; then
    printf 'duplicate skill names: %s\n' "$dup" >&2
    return 1
  fi
}

check_frontmatter_descriptions() {
  local root="$1" f val
  for f in "$root"/han-*/skills/*/SKILL.md "$root"/.claude/skills/*/SKILL.md; do
    [ -f "$f" ] || continue
    val=$(awk '/^---/{c++; if (c > 1) exit; next} c == 1 && /^description:/{v = substr($0, 14); gsub(/^[[:space:]]+|["\x27]+$/, "", v); print v; exit}' "$f")
    case "$val" in
      "" | "|" | ">" | "|-" | ">-")
        # folded or literal block: content must follow on indented lines
        val=$(awk '/^description:/{d = 1; next} d && /^---/{exit} d && /^[[:space:]]+[^[:space:]]/{print "folded"; exit}' "$f")
        ;;
    esac
    if [ -z "$val" ]; then
      printf 'empty description: %s\n' "$f" >&2
      return 1
    fi
  done
}

# Assertion 6, discovery shape (the in-repo proxy for the CLI's discovery per
# D-7): exactly 45 plugin skills through marketplace sources, exactly 2 marked
# internal skills through the .claude container.
check_discovery_shape() {
  local root="$1" plugin internal
  plugin=$( (cd "$root" && find han-*/skills -mindepth 1 -maxdepth 1 -type d 2>/dev/null) | wc -l)
  internal=$( (cd "$root" && find .claude/skills -mindepth 1 -maxdepth 1 -type d 2>/dev/null) | wc -l)
  if [ "$plugin" -ne 45 ]; then
    printf 'expected 45 plugin skills, found %s\n' "$plugin" >&2
    return 1
  fi
  if [ "$internal" -ne 2 ]; then
    printf 'expected 2 internal skills, found %s\n' "$internal" >&2
    return 1
  fi
}

@test "no markdown link in a skill folder resolves outside that folder" {
  no_links_escape_skill_folders "$REPO_ROOT"
}

@test "no markdown link in a skill folder points at a missing shipped file" {
  no_links_dangle_shipped_content "$REPO_ROOT"
}

@test "the dangling check fails on a built fixture that links a missing reference" {
  root="$BATS_TEST_TMPDIR/dangle"
  mkdir -p "$root/han-fixture/skills/demo/references"
  printf -- '---\nname: demo\ndescription: A demo.\n---\n\n[x](./references/gamma.md)\n' \
    >"$root/han-fixture/skills/demo/SKILL.md"
  if no_links_dangle_shipped_content "$root"; then
    echo "dangling check passed on a fixture linking a missing reference" >&2
    false
  fi
}

# Both directions of the exclusion: scaffold and destination-layout links pass,
# and a real shipped-content link still fails in the same fixture.
@test "the dangling check ignores scaffolds but still catches shipped-content links" {
  root="$BATS_TEST_TMPDIR/whitelist"
  mkdir -p "$root/han-fixture/skills/demo/references"
  printf -- '---\nname: demo\ndescription: A demo.\n---\n\nSee the plan [p](../feature-specification.md) and the installed docs at [d](docs/skills/skill-name.md).\n' \
    >"$root/han-fixture/skills/demo/SKILL.md"
  printf '# Template\nLinks [x](./feature-technical-notes.md) and {placeholder} examples.\n' \
    >"$root/han-fixture/skills/demo/references/scaffold-template.md"
  no_links_dangle_shipped_content "$root"
  printf '\nMissing shipped file [y](./references/absent.md).\n' >>"$root/han-fixture/skills/demo/SKILL.md"
  if no_links_dangle_shipped_content "$root"; then
    echo "dangling check passed after a shipped-content link went missing beside the scaffolds" >&2
    false
  fi
}

@test "every skill frontmatter name is unique and equals its folder basename" {
  check_frontmatter_names "$REPO_ROOT"
}

@test "every skill frontmatter description is non-empty" {
  check_frontmatter_descriptions "$REPO_ROOT"
}

@test "the discovery set is exactly 45 plugin skills plus 2 internal skills" {
  check_discovery_shape "$REPO_ROOT"
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

# Shared grammar for the variable-scan assertions (4 and 9): fail listing every
# markdown file in a skill folder that contains the literal token, with the
# vacuity guard built in. Takes a repository root so fixtures run the same code.
# The single quotes at call sites are deliberate: tokens are matched byte for
# byte, nothing may expand.
# shellcheck disable=SC2016
check_no_literal_in_skill_md() {
  local root="$1" token="$2" label="$3"
  local file bad=0 files=0
  while IFS= read -r file; do
    files=$((files + 1))
    if grep -qF -- "$token" "$file"; then
      printf '%s: %s\n' "$label" "$file" >&2
      bad=1
    fi
  done <<EOF
$(skill_markdown_files "$root")
EOF
  [ "$files" -gt 0 ] || {
    printf 'no skill markdown files discovered under: %s\n' "$root" >&2
    return 1
  }
  [ "$bad" -eq 0 ]
}

# Seed of release-guard assertion 4 (plan D-5), landed early by W-4 because the
# portable-configuration rewrite removes the dependency it guards. After a
# channel install there is no plugin root, so no markdown file in a skill folder
# may name `${CLAUDE_PLUGIN_ROOT}` — not in a probe, not in an allowed-tools
# grant, not in an instruction path string.
check_no_plugin_root() {
  # shellcheck disable=SC2016
  check_no_literal_in_skill_md "$1" 'CLAUDE_PLUGIN_ROOT' 'names the plugin root'
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

# Seed of release-guard assertion 9 (plan D-5/D-13): the skill-directory
# variable is a Claude Code built-in the agent-skills specification does not
# define, so shipped skill content references bundled files by skill-root-
# relative paths instead. Same folder-wide scope as assertion 4.
@test "no markdown file in a skill folder names the skill-dir variable" {
  # shellcheck disable=SC2016
  check_no_literal_in_skill_md "$REPO_ROOT" 'CLAUDE_SKILL_DIR' 'names the skill-dir variable'
}

@test "the skill-dir check fails on a built fixture that names the variable" {
  root="$BATS_TEST_TMPDIR/skilldir"
  mkdir -p "$root/han-fixture/skills/demo"
  # shellcheck disable=SC2016
  printf 'run ${CLAUDE_SKILL_DIR}/scripts/thing.sh during the step\n' \
    >"$root/han-fixture/skills/demo/SKILL.md"
  # shellcheck disable=SC2016
  if check_no_literal_in_skill_md "$root" 'CLAUDE_SKILL_DIR' 'names the skill-dir variable'; then
    echo "skill-dir check passed on a fixture that names the variable" >&2
    false
  fi
}

# Seed of release-guard assertion 3 (plan D-5/D-9), landed by W-6 with the
# declarations it guards. The CLI discovers skills from the root marketplace
# manifest, so each han-* entry's declared ./skills/<name> set must equal the
# sorted on-disk inventory of its source — the grouped listing is only true if
# the declaration restates the tree. Prettier owns the JSON bytes, so this
# parses with Node and compares sets; it never byte-greps the arrays. The `han`
# meta entry declares none; no package plugin.json declares skills.
check_manifest_declarations() {
  node -e '
    const fs = require("fs"), path = require("path");
    const root = process.argv[1];
    const catalog = path.join(root, ".claude-plugin", "marketplace.json");
    if (!fs.existsSync(catalog)) { console.error("missing manifest: " + catalog); process.exit(1); }
    const m = JSON.parse(fs.readFileSync(catalog, "utf8"));
    let bad = 0;
    const fail = (msg) => { console.error(msg); bad = 1; };
    for (const e of m.plugins) {
      if (!e.name.startsWith("han-")) continue;
      const dir = path.join(root, e.source, "skills");
      if (!fs.existsSync(dir)) { fail("entry source has no skills folder: " + e.name); continue; }
      const disk = fs.readdirSync(dir).filter((n) => fs.statSync(path.join(dir, n)).isDirectory()).sort();
      const decl = (e.skills || []).map((s) => s.replace(/^\.\/skills\//, "")).sort();
      if (decl.join("|") !== disk.join("|")) {
        fail("declared skills differ from inventory in " + e.name + ": declared=[" + decl.join(", ") + "] disk=[" + disk.join(", ") + "]");
      }
      const pj = path.join(root, e.source, ".claude-plugin", "plugin.json");
      if (fs.existsSync(pj) && "skills" in JSON.parse(fs.readFileSync(pj, "utf8"))) {
        fail("package plugin.json declares skills: " + e.source + "/.claude-plugin/plugin.json");
      }
    }
    const meta = m.plugins.find((e) => e.name === "han");
    if (meta && "skills" in meta) fail("han meta entry declares skills");
    process.exit(bad ? 1 : 0);
  ' "$1"
}

@test "the manifest skills declarations match the packages on disk" {
  check_manifest_declarations "$REPO_ROOT"
}

@test "the manifest check fails on a built fixture whose declaration omits a skill" {
  root="$BATS_TEST_TMPDIR/manifest"
  node -e '
    const fs = require("fs"), path = require("path");
    const root = process.argv[1];
    fs.mkdirSync(path.join(root, ".claude-plugin"), { recursive: true });
    for (const d of ["alpha", "beta"]) fs.mkdirSync(path.join(root, "han-fixture", "skills", d), { recursive: true });
    fs.writeFileSync(
      path.join(root, ".claude-plugin", "marketplace.json"),
      JSON.stringify({ name: "t", plugins: [{ name: "han-fixture", source: "./han-fixture", version: "0.0.0", skills: ["./skills/alpha"] }] })
    );
  ' "$root"
  if check_manifest_declarations "$root"; then
    echo "manifest check passed on a fixture whose declaration omits a skill" >&2
    false
  fi
}

# Seed of release-guard assertion 8 (plan D-5, spec D8), landed by W-8 with the
# section it guards: the README must name both install channels (the plugin
# marker exists today and is guarded against regression; the skills marker is
# the new commitment), the CLI's update command, and the internal-skills
# opt-in. Takes a README path so a fixture runs the same code.
check_readme_channels() {
  local readme="$1" pattern bad=0
  for pattern in '/plugin install han@han' 'npx skills add testdouble/han' 'npx skills update' 'INSTALL_INTERNAL_SKILLS=1'; do
    if ! grep -qF -- "$pattern" "$readme"; then
      printf 'README omits: %s\n' "$pattern" >&2
      bad=1
    fi
  done
  [ "$bad" -eq 0 ]
}

@test "the README names both install channels, the CLI's update command, and the internal-skills opt-in" {
  check_readme_channels "$REPO_ROOT/README.md"
}

@test "the README check fails on a built fixture that omits the skills channel" {
  printf '# Han\n\nInstall with /plugin install han@han.\n' >"$BATS_TEST_TMPDIR/README.md"
  if check_readme_channels "$BATS_TEST_TMPDIR/README.md"; then
    echo "README check passed on a fixture naming only the plugin channel" >&2
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

# W-9: the deliberately broken repository fixture. One tree violating every
# assertion at once; the guard must fail each check it is pointed at before
# the clean suite is allowed to pass. This is the "observe the guard failing"
# step of the work item; the clean-suite pass is the rest of npm test.
@test "the packaging guard fails on a deliberately broken repository fixture" {
  root="$BATS_TEST_TMPDIR/broken"
  mkdir -p "$root/.claude-plugin" "$root/han-fixture/skills/alpha" \
    "$root/han-core/references" "$root/han-fixture/references"
  cat >"$root/.claude-plugin/marketplace.json" <<'MFEST'
{
  "plugins": [
    { "name": "han", "source": "./han", "version": "0.0.0" },
    { "name": "han-fixture", "source": "./han-fixture", "version": "0.0.0", "skills": ["./skills/wrong"] }
  ]
}
MFEST
  cat >"$root/han-fixture/skills/alpha/SKILL.md" <<'SKILL'
---
name: beta
description: ""
---

One line names ${CLAUDE_PLUGIN_ROOT} and ${CLAUDE_SKILL_DIR},
another hardcodes ~/.claude/thing, one links [x](./references/gamma.md),
and one escapes [y](../../../../escape.md).
SKILL
  cat >"$root/README.md" <<'README'
# Han
Install with /plugin install han@han.
README
  printf 'CANONICAL\n' >"$root/han-core/references/config-rule.md"
  printf 'DRIFTED\n' >"$root/han-fixture/references/config-rule.md"

  expect_fail() {
    local label="$1"
    shift
    if "$@" >/dev/null 2>&1; then
      printf '%s passed on the broken fixture\n' "$label" >&2
      return 1
    fi
  }
  check_vendored_row() {
    (cd "$root" &&
      printf 'han-core/references/config-rule.md\than-fixture/references/config-rule.md\n' |
      check_vendored_placement_and_identity)
  }
  expect_fail "assertion 1 (name equals folder)" check_frontmatter_names "$root"
  expect_fail "assertion 1 (description non-empty)" check_frontmatter_descriptions "$root"
  expect_fail "assertion 2 (escape clause)" no_links_escape_skill_folders "$root"
  expect_fail "assertion 2 (dangling clause)" no_links_dangle_shipped_content "$root"
  expect_fail "assertion 3 (manifest declarations)" check_manifest_declarations "$root"
  expect_fail "assertion 4 (plugin root)" check_no_plugin_root "$root"
  expect_fail "assertion 5 (configuration home)" check_no_hardcoded_home "$root"
  expect_fail "assertion 6 (discovery shape)" check_discovery_shape "$root"
  expect_fail "assertion 7 (vendored identity)" check_vendored_row
  expect_fail "assertion 8 (README channels)" check_readme_channels "$root/README.md"
  expect_fail "assertion 9 (skill-dir variable)" \
    check_no_literal_in_skill_md "$root" 'CLAUDE_SKILL_DIR' 'names the skill-dir variable'
}
