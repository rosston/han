# Feature Implementation Plan: npx skills compatibility for Han

This plan adds `npx skills` as a second install channel for Han. The CLI installs Han's 47 skills (the 45 plugin skills plus the 2 repo-maintenance skills) onto every agent the CLI supports, and the skills run there without the plugin. The plugin channel is unchanged, and both channels read the same skill folders, so every change below ships to both channels from one source. The work is a corpus-wide rewrite of the skill folders plus a packaging guard that fails before release when the compatibility contract drifts. One thing to know before reading further: the guard never runs the CLI. It pins repo-side invariants, and the CLI-facing checks run as a maintainer end-to-end pass at release ([D-7](artifacts/implementation-decision-log.md#d-7-discovery-set-verification-without-invoking-the-cli)).

## Outcome

When this plan is executed, a developer on any agent the `npx skills` CLI supports can run `npx skills add testdouble/han`. They see the 45 public skills listed and grouped by plugin package, install the ones they want, and run them. Each installed skill is one self-contained folder: every rule file it follows travels inside it, its bundled scripts and files are referenced by paths relative to the skill folder, and personal-configuration resolution behaves the same as a plugin install. Where a skill would dispatch a specialist agent, the skill performs the step itself and says so once per run. The two repo-maintenance skills stay hidden from the default listing and install only on explicit opt-in.

In the repo, the compatibility contract is guarded. A packaging test in `test/` fails on every change that breaks self-containment, manifest drift, hardcoded configuration homes, plugin-root or skill-dir variable dependencies, or vendored-copy drift, before anything ships ([D-1](artifacts/implementation-decision-log.md#d-1-packaging-guard-location-and-role), [D-5](artifacts/implementation-decision-log.md#d-5-guard-assertion-list)). The README documents both channels side by side. Han maintainers run a short end-to-end pass with the real CLI at release; CI never invokes the CLI ([D-7](artifacts/implementation-decision-log.md#d-7-discovery-set-verification-without-invoking-the-cli)).

## User Stories

- **US-1:** As a developer on any agent the CLI supports, I want `npx skills add testdouble/han --list` to show Han's 45 public skills grouped by plugin package, so that I can see the catalog before installing.
- **US-2:** As a developer, I want each installed skill to arrive as one self-contained folder, so that the skill runs with nothing installed outside that folder.
- **US-3:** As a developer, I want a skill to resolve my personal configuration directory the same way on a channel install as on a plugin install, so that my `.han/config.md` is honored on every agent.
- **US-4:** As a developer running a skill that would dispatch a specialist agent, I want the skill to perform the step itself and tell me once what was substituted, so that the skill still runs and I know the review is no longer independent.
- **US-5:** As a developer with a partial install, I want cross-skill references to use plain skill names and missing skills to be named at the point of use, so that I know what to install next.
- **US-6:** As a Han maintainer, I want a packaging guard that fails before release when the compatibility contract drifts, so that the channel never ships a broken install.
- **US-7:** As a developer reading the README, I want both install channels documented side by side with the update command and the channel's limits, so that I can pick the right channel.
- **US-8:** As a developer, I want the two repo-maintenance skills hidden from the default listing but installable on explicit opt-in, so that the public catalog carries only project-facing skills.

## Constraints and Boundaries

- **Driving constraint:** the operator asked for parity with mattpocock/skills as a second install channel, with the plugin channel staying the full install (see [scope-boundary.md](artifacts/scope-boundary.md), Direction of Travel).
- **Recorded boundary:** the operator's written request in conversation is the only boundary record. No ticket, issue, or pull request exists, and no exclusions were stated ([scope-boundary.md](artifacts/scope-boundary.md)).
- **Out of scope:**
  - installing specialist agents or shared scripts over the skills channel (the CLI copies skill folders only)
  - changes to the `npx skills` CLI or to mattpocock/skills
  - rewriting skill content beyond the eight committed rewrite classes (link targets, setup probes, dispatch steps, vendored rules, hardcoded configuration-home paths, missing-reference handling, reference forms, skill-directory path variables)
- **Watch after ship:** whether every target agent's shell resolves skill-root-relative script paths. The eighth rewrite class removes the `${CLAUDE_SKILL_DIR}` dependency; the relative form is the agent-skills specification's prescribed way to reference bundled files, and the release end-to-end pass observes a script-invoking skill on a non-Claude agent.

## Implementation Approach

The feature adds no runtime machinery of its own. The CLI already discovers, installs, and updates skills from a marketplace manifest; the work makes each skill folder satisfy that model's one-folder install contract and guards the result. Three pieces carry the weight. A one-time codemod rewrites the 47 skill folders. A sync script keeps vendored rule copies identical to their canonical files. A packaging guard asserts the contract on every change. The subsections below pin each contract in concrete form and name the decisions it rests on.

### The packaging guard and its assertions

A new Bats file, `test/skills-packaging.bats`, guards the contract on every change. It sits at harness level, alongside the existing Codex packaging guard, and `npm test` picks it up with no CI change ([D-1](artifacts/implementation-decision-log.md#d-1-packaging-guard-location-and-role)). The guard asserts nine invariants ([D-5](artifacts/implementation-decision-log.md#d-5-guard-assertion-list)):

1. Every skill has a unique, non-empty name and description, and the name equals the folder basename. The agent-skills specification requires the name to match the parent directory, and the CLI installs the folder, so the folder name is the installed identity.
2. No markdown link in any `.md` file inside a skill folder resolves outside that folder or dangles. The shared link grammar skips fenced code blocks and inline code spans.
3. Each marketplace entry's declared `./skills/<name>` set equals the sorted on-disk inventory of its source, the `han` meta entry declares none, and no package `.claude-plugin/plugin.json` declares `skills`.
4. No skill `.md` file contains `CLAUDE_PLUGIN_ROOT`.
5. No configuration-home literal (`~/.claude`, `$HOME/.claude`, `${HOME}/.claude`) appears outside the pinned portable line.
6. The discovery inputs list exactly the intended set: 45 plugin skills plus the 2 marked-internal repo skills, with the byte-exact marker on exactly those 2.
7. Vendored rule copies are byte-identical to their canonical files, at both the package level and the skill level.
8. The README names both install channels, the CLI's update command, and the internal-skills opt-in.
9. No skill `.md` file contains `CLAUDE_SKILL_DIR` — the eighth rewrite class's permanent guard ([D-13](artifacts/implementation-decision-log.md#d-13-eighth-rewrite-class-skill-root-relative-references)).

The guard inherits the Codex packaging test's portability constraints. It runs on bash 3.2 (no `mapfile`, `declare -A`, or globstar). It greps one named file at a time and never `-r`. It uses Node wherever `npm test` runs (the Bats bin is a Node script). So it parses the marketplace JSON with Node and compares sets instead of byte-grepping Prettier's formatting ([D-9](artifacts/implementation-decision-log.md#d-9-manifest-array-shape-and-guard-parsing)). The guard never invokes the CLI. Assertions 3 and 6, plus the marker half of 6, are an in-repo proxy for the CLI's discovery. The CLI-facing checks (the real listing, the sandbox install, the plugin-channel load) run as a maintainer end-to-end pass at release ([D-7](artifacts/implementation-decision-log.md#d-7-discovery-set-verification-without-invoking-the-cli)). Invoking the CLI in CI was considered and deferred: it is network-dependent, version-drifting, and slow, and it reopens if the CLI ships an offline discovery mode.

### The sync script and the canonical map

One repo-root script, `scripts/sync-vendored-files.sh`, with its Bats file `scripts/sync-vendored-files.bats` beside it, keeps every vendored rule copy identical to its canonical file ([D-2](artifacts/implementation-decision-log.md#d-2-sync-machinery-and-the-canonical-map), [D-11](artifacts/implementation-decision-log.md#trivial-decisions)). The map inside the script is explicit: one canonical owner per shared rule file. A sort-derived rule is refuted by evidence, because the first sorted copy of `config-rule.md` is han-atlassian's while the canonical owner is han-core. The owners:

- han-core: `config-rule.md`, `evidence-rule.md`, `yagni-rule.md`, `collaborative-stop-rule.md`
- han-communication: `readability-rule.md`, `writing-voice.md`, `explanation-rule.md`
- han-planning: `planning-boundary-rule.md`, `scope-justification-rule.md`, `operator-escalation-rule.md`, `contract-pinning-rule.md`, `synthesis-failure-rule.md`
- Skill- and repo-owned canonicals the map also names: `han-planning/skills/plan-a-feature/references/feature-technical-notes-template.md` and `docs/semantic-versioning.md`

The script re-syncs the package-level vendored copies in place. It vendors into each skill folder that links a mapped file (link-derived destinations). It also carries explicit destination rows for path-string references that are not markdown links: the readability and explanation rules in the two guidance skills, and the guidance corpus tree that `skill-builder` and `agent-builder` read. It refuses to overwrite an existing file that differs from canonical. Its `--list` mode prints one line per managed copy, and the guard consumes that output instead of duplicating the map:

```text
$ scripts/sync-vendored-files.sh --list
han-core/references/config-rule.md	han-coding/references/config-rule.md
han-core/references/config-rule.md	han-coding/skills/code-review/references/config-rule.md
```

The grammar: `canonical_path<TAB>destination_path`, repo-relative, LF, sorted, no header.

### Vendored copies and rewritten links

The CLI installs exactly one folder per skill, so every file a skill reads at runtime must live inside that folder ([D-3](artifacts/implementation-decision-log.md#d-3-vendored-copy-location-and-rewritten-link-forms)). Shared rule files are vendored into each skill that links them, at `{skill}/references/<basename>`, and the links are rewritten to the vendored copies. The rewritten forms are fixed:

- From `{skill}/SKILL.md`: a link whose target is `../../references/<rule>.md` is rewritten to `./references/<rule>.md`.
- From a file in `{skill}/references/`: a link whose target is `../../../references/<rule>.md` is rewritten to `./<rule>.md`.

The codemod and the guard share one link grammar: a markdown link target is any `](…)` outside fenced code blocks and outside inline code spans. Four escaping links in two skills (`han-release`, `iterative-plan-review`) are not the mechanical pattern; each is vendored and rewritten by hand judgment within the same pass. The guidance corpus the authoring skills read is vendored the same way.

The 47-skill rewrite is delivered by a one-time codemod with named passes and a `--dry-run` diff mode, so the diff is reviewable pass by pass. The codemod is not retained after the migration; the guard owns the invariants afterward ([D-6](artifacts/implementation-decision-log.md#d-6-one-time-migration-codemod)).

### Skill-root-relative references

Fifteen skills invoke bundled scripts or read bundled files through `${CLAUDE_SKILL_DIR}`, a Claude Code built-in the agent-skills specification does not define. The eighth rewrite class rewrites every such reference to a skill-root-relative path, the form the specification itself prescribes for referencing bundled files ([D-13](artifacts/implementation-decision-log.md#d-13-eighth-rewrite-class-skill-root-relative-references)):

- `${CLAUDE_SKILL_DIR}/scripts/foo.sh` becomes `scripts/foo.sh`.
- `${CLAUDE_SKILL_DIR}/references/x.md` becomes `references/x.md`.

The measured scope is 57 reference sites across the skill folders: 28 in `SKILL.md` files across 15 skills, 30 script invocations, 36 file reads, and 9 carrying both, plus the per-skill `references/` and `assets/` files and the guidance corpus the authoring skills read. The vendored corpus copies carry the rewritten references on the next sync run. The guard's assertion 9 fails on any skill `.md` file that still contains the variable. Whether every target agent's shell resolves a skill-root-relative script path is agent-side; the release end-to-end pass observes a script-invoking skill on a non-Claude agent.

### Portable configuration resolution

After a channel install there is no plugin root, so every skill's configuration probe breaks. The resolution moves into the skill's own instructions, as one byte-identical line in each of the 45 plugin skills, in the Project Context block where the probe stood ([D-4](artifacts/implementation-decision-log.md#d-4-pinned-portable-resolution-line)):

```markdown
- personal config directory: $CLAUDE_CONFIG_DIR when that variable is set, otherwise $HOME/.claude (the agent's own configuration-directory override and its default)
```

The matching `Bash(bash "${CLAUDE_PLUGIN_ROOT}/scripts/han-config-dir.sh")` grant comes out of `allowed-tools` in the same change. The project-configuration read (`.han/config.md` first in the resolution order) becomes a Read-tool instruction rather than a command-substitution probe. Instruction text is executed by every agent; probe blocks are a feature of one agent's skill format (T5). Hardcoded configuration-home paths in skill bodies are rewritten to the resolved directory, and the `${CLAUDE_PLUGIN_ROOT}` path strings in the guidance skills repoint at the vendored copies.

The script `scripts/han-config-dir.sh` stays, because the plugin channel ships it. Its test is repurposed: the probe/grant pairing tests retire, the resolver-behavior and script-exists tests stay, and a new test pins the portable line byte-identically in every plugin skill ([D-10](artifacts/implementation-decision-log.md#d-10-the-han-config-dir-script-and-its-test)). CONTRIBUTING.md and the skill-building-guidance context-injection doc are updated in the same change, because their current text documents the probe pattern the rewrite removes.

### Manifest skills declarations

The root marketplace manifest declares each plugin's skills explicitly. That is the CLI's documented discovery contract, and it produces the grouped listing ([D-9](artifacts/implementation-decision-log.md#d-9-manifest-array-shape-and-guard-parsing)). All 13 `han-*` entries gain a `skills` array in Prettier's expanded shape; the `han` meta entry gains none, because `han/` ships no `skills/` folder:

```json
    {
      "name": "han-core",
      "source": "./han-core",
      "description": "The shared foundation of the Han suite: ...",
      "version": "3.2.0",
      "skills": [
        "./skills/pairing",
        "./skills/project-discovery"
      ]
    }
```

Paths are `./skills/<name>`, relative to the entry's `source`. Because Prettier owns the JSON bytes, the guard parses the manifest with Node and compares sets; it never byte-matches the arrays. In the plugin channel the entry declaration is appended to the plugin's own manifest under strict mode, so the declaration must be a pure restatement of the conventional inventory. The guard's assertion 3 proves the restatement, and a local marketplace install at release confirms no skill double-loads (T4).

### The internal-skill marker

The two repo-maintenance skills carry the CLI's internal marker, appended as the last frontmatter key, byte-exact ([D-12](artifacts/implementation-decision-log.md#trivial-decisions)):

```yaml
metadata:
  internal: true
```

With the marker, the CLI hides them from the default listing and installs them only when the installer sets `INSTALL_INTERNAL_SKILLS=1` (or `true`). Run outside the Han repository, either skill says it maintains Han's own repository and stops. Agents that do not implement the marker ignore it, so Han's own plugin-based dev setup is unaffected. The discovery-set shape the guard pins: 45 public plugin skills plus the 2 marked-internal repo skills.

## Work Units and Sequencing

Nine work units, sized to ship. Build order: WU-1, WU-2, WU-3, WU-4, WU-5, WU-6, WU-9, WU-8, then WU-7. Three ordering rules come from files the units share. WU-4, WU-5, and WU-9 run after WU-3 because they edit the same skill files. The guard's README assertion (assertion 8) makes WU-8 a dependency of WU-7, and assertion 9 makes WU-9 one as well ([D-8](artifacts/implementation-decision-log.md#d-8-work-unit-sequencing-and-the-same-change-constraint)). WU-4 also carries the same-change constraint: the portable-line rewrite and the `han-config-dir.bats` surgery land in one change, or the suite goes red.

| #   | Work Unit | Story | Delivers | Justification | Depends On | Verification |
| --- | --------- | ----- | -------- | ------------- | ---------- | ------------ |
| 1 | Internal-skill marker and repo-stop | US-8 | The byte-exact `metadata:` / `internal: true` frontmatter block appended as the last key in the two repo-maintenance skills' SKILL.md files, plus each skill's stop-outside-the-Han-repo behavior | Spec D4/T3: the two maintenance skills maintain Han's own repo and stay out of the public listing; the marker is the CLI's documented mechanism ([D-12](artifacts/implementation-decision-log.md#trivial-decisions)) | — | Guard assertion 6; e2e listing shows 45 by default and 47 with `INSTALL_INTERNAL_SKILLS=1` |
| 2 | Sync machinery | US-2 | `scripts/sync-vendored-files.sh` with `scripts/sync-vendored-files.bats` beside it: the explicit canonical map, package-level re-sync in place, link-derived skill-level vendoring, path-string destination rows, refuse-to-overwrite, and the `--list` contract | Spec D3: vendored copies must stay identical to canonical; the repo convention is edit-canonical-then-resync, and no checked-in sync exists today ([D-2](artifacts/implementation-decision-log.md#d-2-sync-machinery-and-the-canonical-map), [D-11](artifacts/implementation-decision-log.md#trivial-decisions)) | — | The sync script's Bats file green under `npm test`; guard assertion 7 consumes `--list` |
| 3 | Vendored copies and link rewrites | US-2 | The one-time codemod (named passes, `--dry-run` diff mode, not retained) rewriting the escaping links across the 47 skills, plus the first sync run that places the vendored copies, including the four special-case links in `han-release` and `iterative-plan-review` | Spec D3/T2: the CLI installs one folder per skill, and all 47 skills carry upward links today ([D-3](artifacts/implementation-decision-log.md#d-3-vendored-copy-location-and-rewritten-link-forms), [D-6](artifacts/implementation-decision-log.md#d-6-one-time-migration-codemod)) | WU-2 | Guard assertions 2 and 7; the codemod's `--dry-run` diff reviewed pass by pass |
| 4 | Portable configuration resolution | US-3 | The pinned line in the 45 plugin skills, the `han-config-dir.sh` grant removed from `allowed-tools`, the hardcoded-home fixes, the `CLAUDE_PLUGIN_ROOT` path-string repoints, and in the same change: `scripts/han-config-dir.bats` surgery, plus CONTRIBUTING.md and the context-injection guidance doc | Spec D5/T5: the plugin root does not exist after a channel install, and the resolution must live in instruction text every agent executes; claim C1 requires the rewrite and the test surgery in one change ([D-4](artifacts/implementation-decision-log.md#d-4-pinned-portable-resolution-line), [D-8](artifacts/implementation-decision-log.md#d-8-work-unit-sequencing-and-the-same-change-constraint), [D-10](artifacts/implementation-decision-log.md#d-10-the-han-config-dir-script-and-its-test)) | WU-2 | Guard assertions 4 and 5; `han-config-dir.bats` green; `npm run lint` |
| 5 | Dispatch substitution and cross-skill references | US-4, US-5 | The once-per-run substitution note at a fixed anchor in the 36 agent-referencing skills, reference-form normalization to plain names, and missing-reference handling | Spec D2/D9: 36 of 45 plugin skills dispatch agents the channel does not carry, and references must resolve by plain name on partial installs ([spec D2](artifacts/decision-log.md#d2-standalone-degradation-for-agent-dispatch), [spec D9](artifacts/decision-log.md#d9-cross-skill-references)) | WU-3, WU-4 ([D-8](artifacts/implementation-decision-log.md#d-8-work-unit-sequencing-and-the-same-change-constraint)) | Maintainer e2e: a standalone run shows the note; sandbox runs on a non-Claude agent |
| 6 | Manifest skills arrays | US-1 | `"skills": ["./skills/<name>", ...]` arrays on the 13 `han-*` entries in `.claude-plugin/marketplace.json`, in Prettier's expanded shape; none on the `han` meta entry | Spec D6/T1: declared skills are the CLI's documented discovery contract and produce the grouped listing ([D-9](artifacts/implementation-decision-log.md#d-9-manifest-array-shape-and-guard-parsing)) | — | Guard assertion 3; `npm run lint` (Prettier owns the JSON bytes) |
| 7 | Packaging guard | US-6 | `test/skills-packaging.bats` with the nine assertions | Spec D7: the contract fails before release on drift; the repo already guards the Codex surface the same way ([D-1](artifacts/implementation-decision-log.md#d-1-packaging-guard-location-and-role), [D-5](artifacts/implementation-decision-log.md#d-5-guard-assertion-list), [D-7](artifacts/implementation-decision-log.md#d-7-discovery-set-verification-without-invoking-the-cli), [D-11](artifacts/implementation-decision-log.md#trivial-decisions)) | WU-1, WU-2, WU-3, WU-4, WU-6, WU-8, WU-9 | `npm test` green; the guard observed failing on a deliberately broken fixture first |
| 8 | README both-channels section | US-7 | The README section documenting both install channels side by side, the CLI's update command, what the skills channel does not carry, the degraded behaviors, the internal-skills opt-in, and one-channel-per-agent advice | Spec D8: the README is where install instructions are found | WU-6 | Guard assertion 8; `npm run lint` |
| 9 | Skill-root-relative references | US-2 | The eighth rewrite class: every `${CLAUDE_SKILL_DIR}` path reference in shipped skill content rewritten to a skill-root-relative path (`scripts/foo.sh`, `references/x.md`) across the 15 skills' `SKILL.md` files, the per-skill `references/` and `assets/` files, and the guidance corpus, plus a sync re-run so the vendored corpus copies carry the rewritten references | Spec D10/T6: the variable is a Claude Code built-in the agent-skills specification does not define, and the specification prescribes skill-root-relative paths for bundled files; committed by the operator 2026-10-16 ([D-13](artifacts/implementation-decision-log.md#d-13-eighth-rewrite-class-skill-root-relative-references)) | WU-3 | Guard assertion 9; `npm run lint`; maintainer e2e: a script-invoking skill (for example `tdd`) runs on a non-Claude agent and its script step succeeds |

## Definition of Done

- [ ] `npm test` is green, including the new guard, and the guard has been observed failing on a deliberately broken fixture before the clean suite passes ([D-1](artifacts/implementation-decision-log.md#d-1-packaging-guard-location-and-role), [D-5](artifacts/implementation-decision-log.md#d-5-guard-assertion-list)).
- [ ] `npm run lint` is green. Prettier owns the manifest bytes and the SKILL.md edits, and the rewrites are line-local, so they are Prettier-stable ([D-9](artifacts/implementation-decision-log.md#d-9-manifest-array-shape-and-guard-parsing)).
- [ ] The guard's nine assertions are enumerated and passing ([D-5](artifacts/implementation-decision-log.md#d-5-guard-assertion-list)).
- [ ] The maintainer end-to-end list (Testing Strategy) has been run and recorded ([D-7](artifacts/implementation-decision-log.md#d-7-discovery-set-verification-without-invoking-the-cli)).
- [ ] Nothing from `## Deferred (YAGNI)` was built, or its `Reopen when:` trigger fired and is recorded.
- [ ] The eighth rewrite class is complete: no skill `.md` file contains `CLAUDE_SKILL_DIR` (guard assertion 9), and the maintainer e2e observes a script-invoking skill (for example `tdd`) running on a non-Claude agent ([D-13](artifacts/implementation-decision-log.md#d-13-eighth-rewrite-class-skill-root-relative-references)).

## Testing Strategy

The behaviors that prove the feature works are CLI- and agent-facing, so they are verified by a maintainer end-to-end pass at release, not in CI. In-repo, three Bats files cover the mechanics.

- **In-repo and CI:** `test/skills-packaging.bats` (the nine assertions), `scripts/han-config-dir.bats` (resolver semantics: the resolution order, the unreadable-versus-absent distinction, the fallback), and `scripts/sync-vendored-files.bats` (the sync machinery). The guard never invokes the CLI; that is YAGNI-deferred with a reopening trigger ([D-7](artifacts/implementation-decision-log.md#d-7-discovery-set-verification-without-invoking-the-cli)).
- **Maintainer e2e, per release:**
  - `npx skills add testdouble/han --list` shows the 45 public skills grouped by plugin
  - `INSTALL_INTERNAL_SKILLS=1` shows 47
  - a sandbox install is self-contained (the guard's link and vendored-identity assertions re-run against the installed copy)
  - a local marketplace install loads each skill exactly once (T4)
  - `npx skills update` refreshes the installed folders
  - a standalone run of a dispatching skill shows the once-per-run substitution note
  - a script-invoking skill (for example `tdd`) runs on a non-Claude agent and its script step succeeds (the eighth rewrite class)
- **Agent-side, not in CI:** the substitution note, missing-skill naming, the resolution order, and the skill-root-relative script invocation are verified by sandbox runs on at least one non-Claude agent (for example Codex or Cursor).
- **Edge cases requiring coverage:**
  - a corrupted or partial install (a missing rule file is named and the skill stops before acting on it)
  - an unreadable project configuration file (named, not treated as absent)
  - an unresolvable personal configuration directory (fallback to the agent default, named)
  - a partial install (missing skill named at the point of use, omissions summarized at the end of the run)

## Risks and Assumptions

### Risks

| ID  | Risk | Impact | Mitigation | Owner |
| --- | ---- | ------ | ---------- | ----- |
| R1  | Whether every target agent's shell resolves skill-root-relative script paths is agent-side and unverified | A script-invoking skill's script step fails on an agent whose shell does not resolve the relative form | The release e2e observes a script-invoking skill on a non-Claude agent; the guard keeps the variable out of shipped skills (assertion 9) | Maintainer |
| R2  | CLI version drift: the contract is pinned to the CLI's docs (npm `skills` v1.7.0, fetched 2026-10-16) | A CLI change breaks the channel silently | The guard pins repo-side invariants; the e2e re-runs per release | Maintainer |
| R3  | The 47-skill rewrite's review burden | A mechanical error ships inside a large diff | The codemod's named passes and `--dry-run` diff ([D-6](artifacts/implementation-decision-log.md#d-6-one-time-migration-codemod)) | Builder |
| R4  | Plugin-channel double-load from the manifest arrays (T4) | Skills load twice in the plugin channel | A local marketplace install before release; the guard asserts the declaration is a pure restatement | Maintainer |
| R5  | Prettier churn on edited SKILL.md files | Lint failures or noisy diffs | Line-local rewrites are Prettier-stable; `npm run lint` verifies | Builder |

### Assumptions

| ID  | Assumption | What Changes If Wrong | Status |
| --- | ---------- | --------------------- | ------ |
| A1  | Vendored copies stay byte-identical via the sync script | Skills drift from the canonical rules; the guard fails | Verified — repo convention, guard-enforced |
| A2  | The CLI discovers Han's skills via the root marketplace.json, the conventional per-source skills folders, and the `.claude/skills/` container | The listing loses skills or grouping | Verified — fetched CLI README 2026-10-16 (T1) |
| A3  | Agents that do not implement the internal marker ignore it, because the marker is CLI-side frontmatter | Han's own dev setup changes behavior | Verified — CLI README |
| A4  | Target agents' shells resolve skill-root-relative script paths (the form the agent-skills specification prescribes for bundled files) | A script-invoking skill's script step fails on an agent whose shell does not resolve the relative form | Runtime-only — verified by the release e2e on a non-Claude agent |
| A5  | The 8 spike harness skills under `docs/plans` are not CLI-discovered | The guard's discovery-set assertion miscounts | Verified — they sit in no plugin source or container directory, and a recursive search runs only when nothing is found |

## Cut for Scope

This is work the work item excludes, not work deferred for lack of evidence. Nothing here carries a reopening trigger, because the recorded boundary already settled it.

### Shipping specialist agents and shared scripts over the skills channel

- **Why cut:** the CLI's install model copies skill folders only. The operator asked for parity with mattpocock/skills, whose channel is also skills-only ([scope-boundary.md](artifacts/scope-boundary.md), Stated Scope and Direction of Travel; the spec's Cut for Scope).
- **Reinstatement route:** the operator says so, or the CLI grows support for non-skill components.
- **Source:** the spec's Cut for Scope, inherited.

## Deferred (YAGNI)

This is work no evidence supports yet, not work the work item excludes. Every entry carries the trigger that would justify revisiting it.

### Invoking `npx skills` inside the packaging guard or CI

- **Why deferred:** evidence — network-dependent, version drift, slow; the in-repo proxy covers the guard's failure modes.
- **Reopen when:** the CLI ships an offline or dry-run discovery mode, or a compatibility bug ships to the channel.
- **Source:** R1, test-engineer (TE-4, claim C5).

### A YAML parser dependency for frontmatter and manifest parsing

- **Why deferred:** simpler version — line-grammar extraction and Node JSON parsing cover the pinned shapes.
- **Reopen when:** frontmatter gains nested keys the line grammar cannot parse.
- **Source:** R1, test-engineer (TE-5, claim C5).

### Static lints for the dispatch disclosure wording, reference normalization, standalone-block presence, and namespaced skill references

- **Why deferred:** evidence — brittle; agent references share the namespaced shape with skill references.
- **Reopen when:** a shipped skill references a nonexistent skill name, users report a missing substitution note, a channel install's dispatch step silently fails, or a namespaced skill reference ships and breaks a partial install.
- **Source:** R1, test-engineer and structural-analyst (TE-6, SA-F-S4, claim C5).

### Retaining the migration codemod after the 47-skill rewrite

- **Why deferred:** evidence — one-time use; the guard owns the invariants afterward.
- **Reopen when:** the CLI's install contract changes (T2), or a second corpus-wide rewrite is needed.
- **Source:** R1, structural-analyst (SA-F-S4, claim C5).

### An npm `sync` script entry for the sync script

- **Why deferred:** simpler version — run the script directly; CONTRIBUTING names the command.
- **Reopen when:** contributors repeatedly mis-invoke it.
- **Source:** R1, structural-analyst (claim C5).

### A `--check` mode on the sync script

- **Why deferred:** simpler version — the packaging guard checks; one checker, not two.
- **Reopen when:** someone runs the sync expecting validation.
- **Source:** R1, structural-analyst (claim C5).

### Per-skill compatibility notes matrix in the README

- **Why deferred:** evidence — which skills degrade which steps is derivable from the skills themselves, and no user has asked for a matrix.
- **Reopen when:** users report confusion about which behaviors need the plugin.
- **Source:** the spec's Deferred (YAGNI), inherited.

### Evaluating installed skills over the skills channel

- **Why deferred:** evidence — Han evaluates skills in-repo today, and nothing shows the installed copies diverge.
- **Reopen when:** a compatibility bug ships to the skills channel.
- **Source:** the spec's Deferred (YAGNI), inherited.

## Open Items

None. Both items raised during planning are resolved: OI-1 (the skills directory listing) is
confirmed — the directory lists Han automatically (2026-10-16). OI-2 (per-skill script invocation
portability) is committed as the eighth rewrite class (operator decision, 2026-10-16; spec D10,
work unit WU-9), with the release end-to-end pass observing a script-invoking skill on a non-Claude
agent.

## Specialist Handoffs for Implementation

- **test-engineer** — re-engage when the guard is written, and again when its observed-failure fixture is built: a deliberately broken copy must fail the guard before the real suite passes. Needs the merged assertion list (Implementation Approach, "The packaging guard and its assertions").
- **structural-analyst** — re-engage when the sync map gains a canonical row, or when a rewrite pass needs a new mechanical handle. Needs the canonical-owner map and the rewritten-link forms (Implementation Approach, "The sync script and the canonical map" and "Vendored copies and rewritten links").

## Sources and Plan Records

- **Feature specification:** [feature-specification.md](feature-specification.md)
- **Specification companions:** [decision log](artifacts/decision-log.md), [team findings](artifacts/team-findings.md), [technical notes](artifacts/feature-technical-notes.md)
- **Discovery notes (measured figures, CLI contract pins, canonical-owner map, skill-dir sweep):** [artifacts/.discovery-notes.md](artifacts/.discovery-notes.md)
- **Scope boundary:** [artifacts/scope-boundary.md](artifacts/scope-boundary.md)
- **Specification decisions inherited / open items to respect:** D1–D10 / none open — the spec's OI-1 is resolved (the directory lists Han automatically, confirmed 2026-10-16) and OI-2 is resolved by operator decision the same day as the eighth rewrite class (spec D10, work unit WU-9); see the iteration history
- **Decision rationale and rejected alternatives:** [artifacts/implementation-decision-log.md](artifacts/implementation-decision-log.md)
- **Team composition and round-by-round history:** [artifacts/implementation-iteration-history.md](artifacts/implementation-iteration-history.md)

## Recommendation

Ship as planned. Both open items are resolved: the skills directory lists Han automatically (OI-1, confirmed 2026-10-16), and the skill-dir variable rewrite is committed as the eighth rewrite class (OI-2, operator decision 2026-10-16; spec D10, work unit WU-9). The release end-to-end pass observes a script-invoking skill on a non-Claude agent to confirm the relative form resolves there.
