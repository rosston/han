#!/usr/bin/env bats
#
# Guards the portable configuration resolution and the resolver script that
# the plugin channel still ships. The probe/grant pairing tests retired with
# the W-4 rewrite (plan D-10): no skill probes the plugin root anymore, the
# resolution is one byte-exact instruction line every agent executes, and the
# plugin-root and configuration-home checks that supersede the pairing tests
# live in test/skills-packaging.bats.

REPO_ROOT="${BATS_TEST_DIRNAME}/.."
SCRIPT_REL='scripts/han-config-dir.sh'
# The portable resolution line, adopted as exact bytes (spec D5, plan D-4). It
# replaces the probe in every plugin skill's Project Context, so the resolution
# lives in instruction text every agent executes rather than in a probe block
# only one agent's skill format runs. The apostrophe is escaped because the
# single quotes must keep `$CLAUDE_CONFIG_DIR` and `$HOME` unexpanded.
# shellcheck disable=SC2016
PINNED_LINE='- personal config directory: $CLAUDE_CONFIG_DIR when that variable is set, otherwise $HOME/.claude (the agent'\''s own configuration-directory override and its default)'

@test "the shared resolver script exists and is executable" {
  [ -x "${REPO_ROOT}/${SCRIPT_REL}" ]
}

@test "the resolver honors CLAUDE_CONFIG_DIR when it is set" {
  run env CLAUDE_CONFIG_DIR=/tmp/probe-fixture bash "${REPO_ROOT}/${SCRIPT_REL}"
  [ "$status" -eq 0 ]
  [ "$output" = "/tmp/probe-fixture" ]
}

@test "the resolver falls back to the home directory when the variable is unset" {
  run env -u CLAUDE_CONFIG_DIR HOME=/tmp/probe-home bash "${REPO_ROOT}/${SCRIPT_REL}"
  [ "$status" -eq 0 ]
  [ "$output" = "/tmp/probe-home/.claude" ]
}

# Every plugin skill must resolve the personal configuration directory with the
# same instruction text, byte for byte, so the resolution behaves identically on
# agents that never run a command-substitution probe.
@test "every plugin skill pins the portable resolution line byte-identically" {
  cd "$REPO_ROOT" || return 1
  skills=0
  for skill in ./*/skills/*/SKILL.md; do
    [ -f "$skill" ] || continue
    grep -qF -- "$PINNED_LINE" "$skill" || {
      echo "the Project Context is missing the pinned portable line in: $skill"
      return 1
    }
    skills=$((skills + 1))
  done
  [ "$skills" -eq 45 ] || {
    echo "expected 45 plugin skills, counted $skills"
    return 1
  }
}

# Spec D5 and plan D-4: the project-configuration read is instruction text every
# agent executes, not a command-substitution probe only one agent's skill format
# runs. The probe spelling is forbidden outright; one byte-exact Read-tool
# instruction replaces it in every skill.
# shellcheck disable=SC2016
@test "every plugin skill resolves the project configuration through instruction text, not a probe" {
  cd "$REPO_ROOT" || return 1
  local skill
  PROJECT_LINE='- project .han/config.md: use the Read tool on .han/config.md in the directory the skill runs from; a read that returns no file is no project configuration'
  for skill in ./*/skills/*/SKILL.md; do
    grep -qF -- "$PROJECT_LINE" "$skill" || {
      echo "missing the project-config read instruction in: $skill"
      return 1
    }
    if grep -qF -- '- project .han/config.md: !' "$skill"; then
      echo "still probes for the project configuration in: $skill"
      return 1
    fi
  done
}

# The plugin channel is unchanged (plan D-10), so every plugin that ships the
# resolver symlink must ship one that resolves. This is keyed on the symlinks
# themselves, not on any skill probe: the probes the old keying hung on are gone.
@test "every plugin shipping the resolver symlink ships a resolvable target" {
  cd "$REPO_ROOT" || return 1
  links=(han-*/scripts/han-config-dir.sh)
  [ "${#links[@]}" -gt 0 ] || {
    echo "no plugin ships ${SCRIPT_REL}"
    return 1
  }
  for link in "${links[@]}"; do
    [ -e "$link" ] || {
      echo "broken or missing symlink: $link"
      return 1
    }
  done
}
