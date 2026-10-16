# Work Items — npx skills compatibility for Han

This file breaks down the [feature implementation plan](feature-implementation-plan.md) into nine independently grabbable work items. Each item is a vertical slice: a narrow but complete path through the layers it touches, verifiable on its own.

> Work items are numbered `W-N` for cross-reference only. `Depends on` lines refer to other work items in this file.

## Shared reference artifacts

- [feature-specification.md](feature-specification.md) — the feature specification defining user stories US-1 through US-8 and behavioral decisions D1–D10.
- [artifacts/scope-boundary.md](artifacts/scope-boundary.md) — the recorded scope boundary: the operator's request, stated exclusions, and direction of travel.
- [artifacts/feature-technical-notes.md](artifacts/feature-technical-notes.md) — technical notes T1–T6 on CLI discovery, install scope, the internal marker, manifest semantics, setup probes, and skill-root-relative references.

## W-1 — Internal-skill marker and repo-stop

**Summary.** The two repo-maintenance skills maintain Han's own repository, not a user's project. They must stay out of the public catalog while remaining installable on request. This adds the CLI's internal marker to their frontmatter and makes each skill stop when run outside the Han repository.

**Work to be done.**
- Add the byte-exact internal marker as the last frontmatter key in each of the two repo-maintenance skills' SKILL.md files.
  - The marker is the two-line block `metadata:` followed by `  internal: true`.
  - The two skills are `han-release` and `han-update-documentation`, both under `.claude/skills/`.
- Add the stop-outside-the-Han-repo behavior to each skill: when run outside the Han repository, the skill says it maintains Han's own repository and stops.

**Justification.** The operator asked for the two repo-maintenance skills to stay hidden from the default listing and install only on explicit opt-in (US-8); the marker is the CLI's documented mechanism (spec D4, technical note T3).

**References.**
- **Plan decisions** — [WU-1](feature-implementation-plan.md#work-units-and-sequencing): the internal-skill marker and repo-stop work unit. [D-12](feature-implementation-plan.md#trivial-decisions): the internal marker's byte-exact frontmatter form.
- **Spec section** — [feature-specification.md](feature-specification.md): D4 (internal maintenance skills) and Primary Flow step 1.
- **Technical note** — [artifacts/feature-technical-notes.md](artifacts/feature-technical-notes.md): T3 (internal-skill marker).

**Acceptance criteria.**
- [ ] The marker block appears byte-exact as the last frontmatter key in both repo-maintenance skills' SKILL.md files.
- [ ] Each skill stops with a message naming the Han repository when run outside it.
- [ ] The discovery set lists exactly 45 public plugin skills plus the 2 marked-internal repo skills, with the byte-exact marker on exactly those 2 (guard assertion 6).

**Depends on.** None.

## W-2 — Sync machinery for vendored rule copies

**Summary.** Vendored copies of shared rule files must stay identical to their canonical owners. The repo convention is to edit the canonical file and then re-sync the copies, but no checked-in sync exists today. This adds a repo-root script that performs the sync, with a test beside it.

**Work to be done.**
- Create `scripts/sync-vendored-files.sh` carrying the explicit canonical map: one canonical owner per shared rule file.
  - Canonical owners: han-core owns `config-rule.md`, `evidence-rule.md`, `yagni-rule.md`, `collaborative-stop-rule.md`; han-communication owns `readability-rule.md`, `writing-voice.md`, `explanation-rule.md`; han-planning owns `planning-boundary-rule.md`, `scope-justification-rule.md`, `operator-escalation-rule.md`, `contract-pinning-rule.md`, `synthesis-failure-rule.md`.
  - The map also names skill- and repo-owned canonicals.
- Implement three row types: package-level re-sync in place, link-derived skill-level vendoring into `{skill}/references/<basename>`, and explicit destination rows for path-string references that are not markdown links.
- Refuse to overwrite an existing file that differs from canonical.
- Add a `--list` mode that prints one line per managed copy.
- Create `scripts/sync-vendored-files.bats` beside the script.

**Justification.** The CLI installs exactly one folder per skill, so every rule file a skill reads at runtime must live inside that folder (US-2, spec D3); the repo convention is edit-canonical-then-resync, and no checked-in sync exists today.

**References.**
- **Plan decisions** — [WU-2](feature-implementation-plan.md#work-units-and-sequencing): the sync machinery work unit. [D-2](feature-implementation-plan.md#d-2-sync-machinery-and-the-canonical-map): the sync script and the canonical map. [D-11](feature-implementation-plan.md#trivial-decisions): file names for the guard and the sync script.
- **Spec section** — [feature-specification.md](feature-specification.md): D3 (self-contained skills).

**Acceptance criteria.**
- [ ] The sync script's Bats file is green under `npm test`.
- [ ] The `--list` mode prints one line per managed copy in the grammar `canonical_path<TAB>destination_path`, repo-relative, LF line endings, sorted, no header.
- [ ] The script refuses to overwrite an existing file that differs from its canonical source.
- [ ] The packaging guard consumes `--list` output for its vendored-identity assertion (assertion 7).

**Depends on.** None.

## W-3 — Vendored copies and link rewrites across 47 skills

**Summary.** The CLI installs exactly one folder per skill, so every file a skill reads at runtime must live inside that folder. All 47 skills currently link to rule files one level above their folder. This vendors the shared rule copies into each skill and rewrites the links to point at the vendored copies.

**Work to be done.**
- Write a one-time codemod with named passes and a `--dry-run` diff mode, so the diff is reviewable pass by pass.
  - The codemod is not retained after the migration; the packaging guard owns the invariants afterward.
- Run the codemod across the 47 skills to place vendored copies of shared rule files at `{skill}/references/<basename>`.
- Rewrite the links to the vendored copies.
  - From a skill's SKILL.md, a link to a shared rule becomes `./references/<rule>.md`.
  - From a file in `{skill}/references/`, a link becomes `./<rule>.md`.
- Handle the four special-case links in `han-release` and `iterative-plan-review` by hand judgment within the same pass; they do not follow the mechanical pattern.
- Run the first sync so the vendored copies are placed and identical to canonical.

**Justification.** The CLI installs one folder per skill (US-2, spec D3, technical note T2), and all 47 skills carry upward links today.

**References.**
- **Plan decisions** — [WU-3](feature-implementation-plan.md#work-units-and-sequencing): the vendored copies and link rewrites work unit. [D-3](feature-implementation-plan.md#d-3-vendored-copy-location-and-rewritten-link-forms): vendored-copy location and rewritten link forms. [D-6](feature-implementation-plan.md#d-6-one-time-migration-codemod): the one-time migration codemod.
- **Spec section** — [feature-specification.md](feature-specification.md): D3 (self-contained skills).
- **Technical note** — [artifacts/feature-technical-notes.md](artifacts/feature-technical-notes.md): T2 (install scope).

**Acceptance criteria.**
- [ ] No markdown link in any `.md` file inside a skill folder resolves outside that folder or dangles (guard assertion 2). The link grammar skips fenced code blocks and inline code spans.
- [ ] Vendored rule copies are byte-identical to their canonical files at both the package level and the skill level (guard assertion 7).
- [ ] The rewritten link forms are: from `{skill}/SKILL.md`, `./references/<rule>.md`; from a file in `{skill}/references/`, `./<rule>.md`.
- [ ] The codemod's `--dry-run` diff is reviewable pass by pass before the real run.

**Depends on.** W-2.

## W-4 — Portable configuration resolution

**Summary.** After a channel install there is no plugin root, so every skill's configuration probe breaks. This moves the personal-configuration resolution into each skill's own instructions, in one byte-identical line that every agent executes.

**Work to be done.**
- Add the pinned portable line to the Project Context block in each of the 45 plugin skills, where the probe stood.
- Remove the matching `Bash(bash "${CLAUDE_PLUGIN_ROOT}/scripts/han-config-dir.sh")` grant from `allowed-tools` in the same change.
- Rewrite hardcoded configuration-home paths in skill bodies to the resolved directory.
- Repoint `${CLAUDE_PLUGIN_ROOT}` path strings in the guidance skills at the vendored copies.
- Repurpose `scripts/han-config-dir.bats` in the same change: retire the probe/grant pairing tests, keep the resolver-behavior and script-exists tests, and add a new test pinning the portable line byte-identically in every plugin skill.
- Update CONTRIBUTING.md and the skill-building-guidance context-injection doc, because their current text documents the probe pattern the rewrite removes.

**Justification.** The plugin root does not exist after a channel install (US-3, spec D5); the resolution must live in instruction text every agent executes (technical note T5). The rewrite and the test surgery must land in one change or the suite goes red (decision D-8).

**References.**
- **Plan decisions** — [WU-4](feature-implementation-plan.md#work-units-and-sequencing): the portable configuration resolution work unit. [D-4](feature-implementation-plan.md#d-4-pinned-portable-resolution-line): the pinned portable resolution line. [D-8](feature-implementation-plan.md#d-8-work-unit-sequencing-and-the-same-change-constraint): work-unit sequencing and the same-change constraint. [D-10](feature-implementation-plan.md#d-10-the-han-config-dir-script-and-its-test): the han-config-dir script and its test.
- **Spec section** — [feature-specification.md](feature-specification.md): D5 (portable configuration resolution).
- **Technical note** — [artifacts/feature-technical-notes.md](artifacts/feature-technical-notes.md): T5 (agent-specific setup probes).

**Acceptance criteria.**
- [ ] The pinned line appears byte-identically in the Project Context block of all 45 plugin skills:
  `- personal config directory: $CLAUDE_CONFIG_DIR when that variable is set, otherwise $HOME/.claude (the agent's own configuration-directory override and its default)`
- [ ] No skill `.md` file contains `CLAUDE_PLUGIN_ROOT` (guard assertion 4).
- [ ] No configuration-home literal (`~/.claude`, `$HOME/.claude`, `${HOME}/.claude`) appears outside the pinned portable line (guard assertion 5).
- [ ] `scripts/han-config-dir.bats` is green under `npm test`.
- [ ] `npm run lint` is green.

**Depends on.** W-2.

## W-5 — Dispatch substitution and cross-skill references

**Summary.** The skills channel carries no specialist agents, so 36 skills that would dispatch one must perform the step themselves and say so. Cross-skill references must use plain skill names so a partial install names what is missing at the point of use.

**Work to be done.**
- Add a once-per-run substitution note at a fixed anchor in each of the 36 agent-referencing skills. The note names what was substituted and states that the independent specialist review is replaced by the calling model's own judgment.
- Normalize cross-skill reference forms to plain skill names, replacing namespaced and slash-command reference forms.
- Add missing-reference handling: name the missing skill at the point of use, continue with the parts that do not need it, stop and name the skill to install when no part can proceed, and summarize omissions at the end of the run.

**Justification.** 36 of 45 plugin skills dispatch agents the channel does not carry (US-4, spec D2), and references must resolve by plain name on partial installs (US-5, spec D9).

**References.**
- **Plan decisions** — [WU-5](feature-implementation-plan.md#work-units-and-sequencing): the dispatch substitution and cross-skill references work unit.
- **Spec sections** — [feature-specification.md](feature-specification.md): D2 (standalone degradation for agent dispatch) and D9 (cross-skill references).

**Acceptance criteria.**
- [ ] A standalone run of a dispatching skill shows the substitution note exactly once per run.
- [ ] A partial install names the missing skill at the point of use and summarizes omissions at the end of the run.
- [ ] Cross-skill references use plain skill names, not namespaced or slash-command forms.
- [ ] Sandbox runs on a non-Claude agent confirm the note appears and the missing-skill naming works.

**Depends on.** W-3, W-4.

## W-6 — Manifest skills arrays

**Summary.** The CLI discovers skills through the root marketplace manifest. Each plugin entry can declare its skills explicitly, and those declarations produce the grouped listing the CLI shows. This adds the declarations to all 13 plugin entries so the listing groups Han's skills by package.

**Work to be done.**
- Add a `"skills"` array to each of the 13 `han-*` entries in `.claude-plugin/marketplace.json`.
  - Each array holds `"./skills/<name>"` paths, relative to the entry's `source`.
  - The shape is Prettier's expanded form: newline after `[`, one path per line.
- Add no `skills` array to the `han` meta entry, because `han/` ships no `skills/` folder.

**Justification.** Declared skills are the CLI's documented discovery contract and produce the grouped listing (US-1, spec D6, technical note T1).

**References.**
- **Plan decisions** — [WU-6](feature-implementation-plan.md#work-units-and-sequencing): the manifest skills arrays work unit. [D-9](feature-implementation-plan.md#d-9-manifest-array-shape-and-guard-parsing): manifest array shape and guard parsing.
- **Spec section** — [feature-specification.md](feature-specification.md): D6 (explicit manifest declarations).
- **Technical note** — [artifacts/feature-technical-notes.md](artifacts/feature-technical-notes.md): T1 (discovery mechanism).

**Acceptance criteria.**
- [ ] Each marketplace entry's declared `./skills/<name>` set equals the sorted on-disk inventory of its source (guard assertion 3).
- [ ] The `han` meta entry declares no `skills` array.
- [ ] No package `.claude-plugin/plugin.json` declares a `skills` key.
- [ ] The array shape matches Prettier's expanded form, and `npm run lint` is green.

**Depends on.** None.

## W-7 — Skill-root-relative references

**Summary.** Fifteen skills reference bundled scripts and files through a Claude Code built-in variable. Other agents do not define that variable, so script steps would fail on those agents. This rewrites every such reference to a skill-root-relative path, the form the agent-skills specification prescribes for bundled files.

**Work to be done.**
- Rewrite every `${CLAUDE_SKILL_DIR}` path reference in shipped skill content to a skill-root-relative path.
  - `${CLAUDE_SKILL_DIR}/scripts/foo.sh` becomes `scripts/foo.sh`.
  - `${CLAUDE_SKILL_DIR}/references/x.md` becomes `references/x.md`.
- Cover the 15 skills' SKILL.md files, the per-skill `references/` and `assets/` files, and the guidance corpus the authoring skills read.
- Re-run the sync so the vendored corpus copies carry the rewritten references.

**Justification.** The variable is a Claude Code built-in the agent-skills specification does not define (US-2, spec D10, technical note T6); the specification prescribes skill-root-relative paths for referencing bundled files.

**References.**
- **Plan decisions** — [WU-9](feature-implementation-plan.md#work-units-and-sequencing): the skill-root-relative references work unit. [D-13](feature-implementation-plan.md#d-13-eighth-rewrite-class-skill-root-relative-references): the eighth rewrite class, skill-root-relative references.
- **Spec section** — [feature-specification.md](feature-specification.md): D10 (skill-directory path variables).
- **Technical note** — [artifacts/feature-technical-notes.md](artifacts/feature-technical-notes.md): T6 (skill-root-relative references).

**Acceptance criteria.**
- [ ] No skill `.md` file contains `CLAUDE_SKILL_DIR` (guard assertion 9).
- [ ] The rewritten forms are skill-root-relative: `scripts/foo.sh` and `references/x.md`.
- [ ] `npm run lint` is green.
- [ ] A maintainer end-to-end pass observes a script-invoking skill (for example `tdd`) running on a non-Claude agent, and its script step succeeds.

**Depends on.** W-3.

## W-8 — README both-channels section

**Summary.** The README is where developers find install instructions. Today it documents only the plugin channel. This adds a section covering both channels side by side, so a developer can pick the right channel for their agent and know what each channel carries.

**Work to be done.**
- Add a README section documenting both install channels side by side.
- Name the CLI's install and update commands.
- State what the skills channel does not carry: specialist agents and shared scripts.
- Name the degraded behaviors: inline dispatch with the once-per-run substitution note.
- Show the internal-skills opt-in for the two repo-maintenance skills.
- Advise one channel per agent.

**Justification.** The README is where install instructions are found (US-7, spec D8).

**References.**
- **Plan decisions** — [WU-8](feature-implementation-plan.md#work-units-and-sequencing): the README both-channels section work unit.
- **Spec section** — [feature-specification.md](feature-specification.md): D8 (README documents both channels).

**Acceptance criteria.**
- [ ] The README names both install channels, the CLI's update command, and the internal-skills opt-in (guard assertion 8).
- [ ] `npm run lint` is green.

**Depends on.** W-6.

## W-9 — Packaging guard

**Summary.** The compatibility contract must fail before release when it drifts. A packaging test guards the contract on every change, the same way the repo already guards the Codex surface. This adds a Bats test with nine assertions covering self-containment, manifest drift, hardcoded paths, variable dependencies, and vendored-copy identity.

**Work to be done.**
- Create `test/skills-packaging.bats` with the nine assertions.
  - Assertion 1: every skill has a unique, non-empty name and description, and the name equals the folder basename.
  - Assertion 2: no markdown link in any `.md` file inside a skill folder resolves outside that folder or dangles.
  - Assertion 3: each marketplace entry's declared `./skills/<name>` set equals the sorted on-disk inventory; the `han` meta entry declares none; no package `plugin.json` declares `skills`.
  - Assertion 4: no skill `.md` file contains `CLAUDE_PLUGIN_ROOT`.
  - Assertion 5: no configuration-home literal appears outside the pinned portable line.
  - Assertion 6: the discovery inputs list exactly 45 plugin skills plus the 2 marked-internal repo skills, with the byte-exact marker on exactly those 2.
  - Assertion 7: vendored rule copies are byte-identical to their canonical files at both the package level and the skill level.
  - Assertion 8: the README names both install channels, the CLI's update command, and the internal-skills opt-in.
  - Assertion 9: no skill `.md` file contains `CLAUDE_SKILL_DIR`.
- Inherit the Codex packaging test's portability constraints: bash 3.2 (no `mapfile`, `declare -A`, or globstar), grep one named file at a time, never `-r`, parse the marketplace JSON with Node and compare sets.
- The guard never invokes the `npx skills` CLI.
- Build a deliberately broken fixture and observe the guard failing before the clean suite passes.

**Justification.** The contract fails before release on drift (US-6, spec D7); the repo already guards the Codex surface the same way after a real incident.

**References.**
- **Plan decisions** — [WU-7](feature-implementation-plan.md#work-units-and-sequencing): the packaging guard work unit. [D-1](feature-implementation-plan.md#d-1-packaging-guard-location-and-role): packaging guard location and role. [D-5](feature-implementation-plan.md#d-5-guard-assertion-list): the guard's nine assertions. [D-7](feature-implementation-plan.md#d-7-discovery-set-verification-without-invoking-the-cli): discovery-set verification without invoking the CLI. [D-11](feature-implementation-plan.md#trivial-decisions): the guard's file name.
- **Spec section** — [feature-specification.md](feature-specification.md): D7 (packaging guard).

**Acceptance criteria.**
- [ ] `npm test` is green, including the new guard.
- [ ] The guard has been observed failing on a deliberately broken fixture before the clean suite passes.
- [ ] The nine assertions are enumerated and passing.

**Depends on.** W-1, W-2, W-3, W-4, W-6, W-7, W-8.

## Cut for Scope

> This is work the work item excludes, not work deferred for lack of evidence. There is no trigger that reopens an entry here; the recorded boundary already settled it.

- **Shipping specialist agents and shared scripts over the skills channel.** The CLI's install model copies skill folders only, so agents and shared scripts cannot travel over this channel. The operator asked for parity with mattpocock/skills, whose channel is also skills-only. Reinstatement route: the operator says so, or the CLI grows support for non-skill components. ([artifacts/scope-boundary.md](artifacts/scope-boundary.md), Stated Scope and Direction of Travel)
