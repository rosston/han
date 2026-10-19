# Implementation Decision Log: npx skills compatibility for Han

<!--
This file records every implementation decision committed while planning npx skills
compatibility for Han. Implementation statements live in
[../feature-implementation-plan.md](../feature-implementation-plan.md); this file captures
the question, rationale, evidence, and rejected alternatives for each. Round-by-round
history lives in [implementation-iteration-history.md](implementation-iteration-history.md).

The behavioral decisions D1–D9 live in the spec's [decision-log.md](decision-log.md) and
are inherited, not re-decided; this log's D-N numbering is its own and does not collide
with the spec's.

## Two-tier format: full vs. trivial decisions

Every decision is classified **full** or **trivial** before it is recorded. A decision is
**full** when any of these signals is present: it has at least one rejected alternative;
the rationale rests on evidence beyond the spec's framing (codebase pattern, measured
figure, specialist finding, or fetched contract); it was driven by or changed by a
discussion round; it has at least one dependent decision; or there is recorded dissent.
A decision is **trivial** otherwise. Eleven decisions are full (D-1 through D-10 and D-13);
two are trivial (D-11, D-12). The D-N counter is shared across both sections.

Cross-referencing invariants:
- `Driven by rounds:` — R# IDs from [implementation-iteration-history.md](implementation-iteration-history.md)
  that added or changed this decision. Settlements made by the plan-synthesizer's own
  re-reading during the synthesis pass are labeled `synthesis (Step 8 evidence)`.
- `Dependent decisions:` — D# IDs of decisions that rest on this one.
- `Referenced in plan:` — sections of [../feature-implementation-plan.md](../feature-implementation-plan.md)
  that cite this decision with an inline parenthetical link.
-->

## Trivial decisions

- D-11: File names — the guard is `test/skills-packaging.bats` and the sync script is `scripts/sync-vendored-files.sh`, with its Bats file beside it. R1's specialists proposed two names for the sync script (`sync-vendored-rules.sh` and `sync-vendored-files.sh`); the plan picks the latter (claim C10). Driven by rounds: R1 (C10 recorded the difference; the synthesis pass picked the name). Dependent decisions: —. Referenced in plan: Implementation Approach, Work Units and Sequencing.
- D-12: The internal marker's byte-exact form — the marker is the frontmatter block `metadata:` / `  internal: true`, appended as the last frontmatter key in each of the two repo-maintenance skills' SKILL.md files. Driven by rounds: R1 (C10 agreement; the CLI's documented marker, T3). Dependent decisions: D-5. Referenced in plan: Implementation Approach, Work Units and Sequencing.
- D-14: The four escaping links' hand judgment at migration time (W-3, 2026-10-16) — han-release's two `writing-voice.md` links and `iterative-plan-review`'s cross-skill template link are vendored (the writing-voice rows derive from the mapped basename; one explicit map row carries the skill-owned template canonical); han-release's `docs/semantic-versioning.md` link is de-linked to a code span instead of vendored, because that repo doc's own `](../han-plugin-builder/...)` links would escape the skill folder from inside any byte-identical vendored copy — vendoring it violates guard assertion 2 or assertion 7 whichever way the copies are handled. The de-linked reference reads true because `han-release` stops outside the Han repository (W-1) and the governing rules are inlined below it. Driven by: W-3 migration census. Dependent decisions: D-2, D-3.
- D-16: Corpus purge vocabulary (W-4, 2026-10-19) — the exact spelling of the plugin-root variable survives only in non-`.md` files (the `references/templates/*.json` examples, which assertions 4 and 9 do not scan), and `.md` sites describe it: `<plugin-root>` and `<default-config-home>` placeholders in code positions, continuing the corpus's existing `<fallback>` style; the measured probe-form table keeps its variable-shape rows with a neutral path suffix (the three stated rules depend on the expansion form, not the suffix); verbatim error quotes elide only the path segment so the searchable classifier phrases ("Blocked by classifier", "Contains expansion") stay findable. Han's own retired probe examples in `context-injection-commands.md` and `troubleshooting.md` were rewritten to the pinned instruction form the plan requires, not just de-literaled. Driven by: W-4 green, D-15. Dependent decisions: —.
- D-17: Propagating canonical edits to managed copies (W-4, 2026-10-19) — drifted destinations are re-copied (`cp`), never deleted-then-synced: `emit_package_rows` derives package-level rows by globbing existing files, so removing a drifted package copy drops its map row and sync can no longer re-place it (measured 223→211→223 on `config-rule.md`). Related vacuity finding: the seeds' first extraction passed green on an undefined root variable because an empty prefix glob matched zero files; both checks now assert a nonzero discovered-file count, and the whitelist accepts exactly the byte-identical pinned line. Driven by: W-4. Dependent decisions: D-15.
- D-18: W-5 substitution-note shape and set membership (2026-10-19) — the note is a `## Standalone degradation` section inserted immediately after the Project Context config paragraph, composed of two byte-identical paragraphs: P1 (agent substitution, once-per-run disclosure, no hard-fail on a missing agent) in the 29 files that actually dispatch agents, and P2 (missing-skill naming at point of use, continue-then-summarize, stop-and-name-install) in the 39 files with cross-skill references; 42 files get the section, 3 get none (`pairing` has no external references; `agent-builder`/`skill-builder` mention `guidance` only as a plain-name routing clause in their descriptions, where there is no point of use to name). Set membership measured, not inherited: the plan's "36 agent-referencing skills" counts files with any namespaced token; the agent-token subset is 28, plus `plan-a-feature-to-confluence`, whose dispatch of `plan-synthesizer` is the only bare-name agent reference in a SKILL.md body. Normalization covered SKILL.md bodies, non-managed `references/` files, and the three rule/corpus canonicals that carried namespaced skill references (`operator-escalation-rule`, `explanation-rule`, `skill-composition`), re-synced via D-17's `cp` rule; agent tokens deliberately stay namespaced — they are the plugin channel's roster, and P1 governs their absence on the channel. Driven by: W-5 measurement. Dependent decisions: spec D2, D9.
- D-19: W-6 AC4 shape nuance (2026-10-19) — Prettier expands a `skills` array one-path-per-line only where the one-line form exceeds the 120-column print width; the four short inventories (`han-core`, `han-ddd`, `han-feedback`, `han-linear`) render one-line, and forcing them expanded would be hand-formatting the tool disowns. AC4 was written assuming uniform expansion, but the plan itself declares "Prettier owns the JSON bytes" and D-9 forbids byte-shape coupling in the guard, which compares sets parsed with Node. AC4 left unticked for the operator: either accept "Prettier's shape" as the criterion (then it is met and lint is green), or widen print width for that file. Driven by: W-6 green step. Dependent decisions: D-9.
- D-20: W-7 teaching inversion and collateral edits (2026-10-19) — `script-execution-instructions.md` is a corpus doc whose thesis was the variable itself ("Use `${CLAUDE_SKILL_DIR}` for all script paths… Never use bare relative paths"), so it was rewritten, not stripped: the numbered-prose/fenced-block/self-containment lessons stand, the path convention inverts to skill-root-relative, and Claude Code's substitution is described generically ("substitutes the skill's own directory into shell command text") so the token count stays zero even in teaching prose — the D-16 vocabulary applied to assertion 9. Two collateral rewrites: guidance SKILL.md's init-guidance steps read "Run `scripts/init-guidance.sh` from the repository root", which the prefix strip made ambiguous between script location and working directory, now "With the repository root as your working directory, run this skill's `scripts/init-guidance.sh`"; and the assertion 4/9 scans were folded into one shared `check_no_literal_in_skill_md` helper when the second variable test would otherwise have copied the grammar. Sites the W-7 boundary does not carry and that stated the retired convention were left for operator ruling and fixed on that approval: `CONTRIBUTING.md` and `.claude/rules/coding-standards/plugin-skills.md` now say skill-root-relative paths; the historical `docs/research/guidance-currency-review.md` row is left as a snapshot of when it was written. Driven by: W-7 green step; operator input 2026-10-19. Dependent decisions: D-13, D-15, D-16.
- D-21: W-8 README layout and assertion-8 seed grammar (2026-10-19) — the both-channels commitment lands as a comparison table plus a degraded-behaviors paragraph directly under `## Installation` (the side-by-side reading) and a `### Skills CLI` subsection after Codex carrying the pinned commands (`npx skills add testdouble/han [--list]`, `INSTALL_INTERNAL_SKILLS=1 npx skills add testdouble/han`, `npx skills update`); the degradation prose appears once, in the overview, and the subsection defers to it rather than restating. The assertion-8 seed greps one README path for four literals — `/plugin install han@han` (names the plugin channel; satisfied today and kept as a regression clause), `npx skills add testdouble/han`, `npx skills update`, `INSTALL_INTERNAL_SKILLS=1` — parameterized by path with a fixture teeth test, matching the assertion-4/9 seed pattern. One-channel-per-agent advice is phrased as the coexistence consequence only (two copies, agent decides), per F15's unverified-precedence caveat. Driven by: W-8. Dependent decisions: D-5 (assertion 8), spec D8.

## Full decisions

### D-1: Packaging guard location and role

- **Question:** Where does the compatibility contract's guard live, and what runs it?
- **Decision:** A new Bats file, `test/skills-packaging.bats`, at harness level alongside the existing Codex packaging guard (`test/codex-packaging.bats`). `npm test` runs Bats over every `*.bats` outside `node_modules`, and CI runs `npm test`, so the guard runs on every change with no CI change. It asserts repo-side invariants only; it never invokes the `npx skills` CLI (D-7).
- **Rationale:** The repo already guards its Codex packaging the same way after a real incident in which two plugins shipped uninstallable, and the skills channel adds the same class of risk. `test/sanity.bats`'s header reserves `test/` for repository-wide structural invariants that cover no single script, which is exactly this guard.
- **Evidence:** `test/codex-packaging.bats` guards the Codex surface and cites its motivating incident; `package.json`'s test script; `.github/workflows/ci.yml` runs `npm test` on ubuntu-latest with Node LTS; `.discovery-notes.md` (Tech stack, Code touch points).
- **Rejected alternatives:**
  - Invoking the CLI inside the guard (in CI) — rejected; network-dependent, version drift, slow; the in-repo proxy covers the failure modes (D-7).
  - Per-package guards — rejected; the contract spans 13 packages plus `.claude/skills`, so per-package machinery means 13 copies of one guard.
  - No guard — rejected; it accepts silent drift, and the Codex incident shows manual verification gets forgotten.
  - Manual verification before release — rejected for the same reason.
- **Specialist owner:** test-engineer
- **Revisit criterion:** CI stops running `npm test`, or a second harness-level guard needs a different home.
- **Dissent (if any):** — (both specialists independently committed to the guard at `test/skills-packaging.bats`, claim C10).
- **Driven by rounds:** R1
- **Dependent decisions:** D-5
- **Referenced in plan:** Implementation Approach (The packaging guard and its assertions), Work Units and Sequencing (WU-7), Definition of Done, Testing Strategy

### D-2: Sync machinery and the canonical map

- **Question:** What keeps the vendored rule copies identical to their canonical files, and where does the sync machinery live?
- **Decision:** One repo-root script, `scripts/sync-vendored-files.sh`, with its Bats file `scripts/sync-vendored-files.bats` beside it (D-11). The script carries an explicit canonical map, one canonical owner per shared rule file, per the discovery notes' R2 addendum, and three row types: (1) package-level vendored copies, re-synced in place; (2) explicit destination rows for path-string references that are not markdown links (the readability and explanation rules in the two guidance skills, and the guidance corpus tree under `han-plugin-builder/skills/guidance/references/`); (3) skill-level vendoring derived from links: for each skill folder, each markdown link whose target basename is a mapped file gets a copy at `{skill}/references/<basename>`. The script refuses to overwrite an existing file that differs from canonical. Its `--list` mode prints one line per managed copy — `canonical_path<TAB>destination_path`, repo-relative, LF, sorted, no header — and the packaging guard consumes that output instead of duplicating the map.
- **Rationale:** The repo convention is "edit the canonical file, re-sync the vendored copies," but no checked-in sync exists today, and the skills corpus is actively edited. One script at the repo root matches the repo's layout conventions (repo-root shared scripts with their Bats tests beside them) and avoids 13 copies of one map. The explicit map is load-bearing: a sort-derived canonical would mislabel `config-rule.md`, whose first sorted package-level copy is han-atlassian's while the canonical owner is han-core.
- **Evidence:** `.discovery-notes.md` R2 addendum (canonical owners verified against the files' self-descriptions and CLAUDE.md); `han-core/references/config-rule.md:17` self-description; measured inventories (`config-rule.md` in 13 packages, byte-identical; `evidence-rule.md` and `yagni-rule.md` in 5; `collaborative-stop-rule.md` in 2); structural-analyst §1; test-engineer Finding 7 (which proposed the sort-derived rule and was refuted).
- **Rejected alternatives:**
  - A sort-derived canonical (first sorted package-level copy per basename) — rejected; refuted by evidence: it mislabels `config-rule.md`'s owner (claim C4, settled in R2).
  - Per-package sync machinery — rejected; 13 copies of one map (YAGNI candidate).
  - An external map config file — rejected; the map is roughly 20 lines and changes rarely.
  - A `--check` mode — rejected; the packaging guard checks; one checker, not two (YAGNI-deferred).
  - An npm `sync` script entry — rejected; run the script directly, and CONTRIBUTING names the command (YAGNI-deferred).
- **Specialist owner:** structural-analyst
- **Revisit criterion:** The canonical owners change, a second corpus-wide sync is needed, or contributors repeatedly mis-invoke the script (the deferred npm-entry trigger).
- **Dissent (if any):** The test-engineer proposed a sort-derived canonical; the structural-analyst proposed the explicit map. Settled by evidence in R2 (claim C4): the explicit map ships, and the sort-derived rule is refuted, not outvoted.
- **Driven by rounds:** R1, R2
- **Dependent decisions:** D-5
- **Referenced in plan:** Implementation Approach (The sync script and the canonical map), Work Units and Sequencing (WU-2), Testing Strategy

### D-3: Vendored-copy location and rewritten link forms

- **Question:** Where do vendored rule copies live inside a skill folder, and what do the rewritten links look like?
- **Decision:** The location contract is `{skill}/references/<basename>`. From `{skill}/SKILL.md`, a link to a shared rule becomes `](./references/<rule>.md)`; from a per-skill `references/*.md` file, it becomes `./<rule>.md`. The codemod and the guard share one link grammar: a markdown link target is any `](…)` outside fenced code blocks and outside inline code spans; HTML comments and blockquotes are scanned. Four escaping links in two skills (`han-release`, `iterative-plan-review`) are not the mechanical pattern; each is vendored and rewritten by hand judgment within the same pass. The guidance corpus the authoring skills read is vendored the same way.
- **Rationale:** The CLI installs exactly one folder per skill (T2), and per-skill `references/` and `scripts/` subfolders ride along, so `{skill}/references/<basename>` is the natural home: it already exists in 32 of 47 skills, never collides with `scripts/`, and matches the repo's existing in-skill link style. Measured scope: 148 `SKILL.md` links across 45 skills, 32 links across 6 skills' references files, 4 special links.
- **Evidence:** `.discovery-notes.md` (Measurements; CLI contract pins); structural-analyst §2 (measured link census and collision analysis: no per-skill file today carries a mapped basename); test-engineer Findings 2 and 3.
- **Rejected alternatives:**
  - Hand edits per skill — rejected; 47 skills and roughly 184 links leave no review story (see D-6).
  - Vendor only the most-linked rules — rejected; the long tail keeps the same failure mode (spec D3's own rejection).
  - A different vendored location (for example a `rules/` subfolder) — rejected; `references/` already exists in most skills and rides along on install.
- **Specialist owner:** structural-analyst
- **Revisit criterion:** The CLI's install contract changes (T2), for example installs stop copying per-skill `references/` subfolders.
- **Dissent (if any):** —
- **Driven by rounds:** R1
- **Dependent decisions:** D-2, D-5
- **Referenced in plan:** Implementation Approach (Vendored copies and rewritten links), Work Units and Sequencing (WU-3)

### D-4: Pinned portable resolution line

- **Question:** How does a skill resolve the personal configuration directory after a channel install, and in what exact form?
- **Decision:** The resolution lives in the skill's own instructions as one byte-identical line in each of the 45 plugin skills' Project Context block, where the probe stood:

  ```markdown
  - personal config directory: $CLAUDE_CONFIG_DIR when that variable is set, otherwise $HOME/.claude (the agent's own configuration-directory override and its default)
  ```

  The matching `Bash(bash "${CLAUDE_PLUGIN_ROOT}/scripts/han-config-dir.sh")` grant is removed from `allowed-tools`. The project-configuration read (`.han/config.md` first in the resolution order) becomes a Read-tool instruction rather than a command-substitution probe, per T5: instruction text is executed by every agent, while probe blocks are a feature of one agent's skill format. Hardcoded configuration-home paths in skill bodies are rewritten to the resolved directory, and `${CLAUDE_PLUGIN_ROOT}` path strings repoint at vendored copies.
- **Rationale:** All 45 plugin skills carry the probe/grant pattern today (90 lines measured), and the plugin root does not exist after a channel install. The helper script is a one-liner, so inlining it removes the dependency without changing resolution semantics. T5 requires instruction text so the resolution never depends on an agent-specific skill-file feature.
- **Evidence:** `.discovery-notes.md` R2 addendum (the pinned line, adopted as exact bytes); `scripts/han-config-dir.sh` prints `${CLAUDE_CONFIG_DIR:-$HOME/.claude}`; measured: 45 of 47 skills reference `CLAUDE_PLUGIN_ROOT`, 90 of those in the probe/grant pattern; spec D5; T5; team-findings F3 and F4.
- **Rejected alternatives:**
  - Keep the plugin-root script probe — rejected; it breaks or silently degrades outside the plugin (spec D5's own rejection).
  - Drop personal-config resolution for channel installs — rejected; it loses user configuration silently (spec D5's own rejection).
- **Specialist owner:** structural-analyst
- **Revisit criterion:** The set of supported agents' configuration-directory override variables changes (claim C7), or T5's probe caveat changes.
- **Dissent (if any):** —
- **Driven by rounds:** R1, R2
- **Dependent decisions:** D-5, D-8, D-10
- **Referenced in plan:** Implementation Approach (Portable configuration resolution), Work Units and Sequencing (WU-4)

### D-5: Guard assertion list

- **Question:** What exactly does the packaging guard assert?
- **Decision:** Nine assertions, merged from both specialists' lists plus the eighth rewrite class's guard: (1) every skill has a unique non-empty name and description, and the name equals the folder basename; (2) no markdown link in any `.md` file inside a skill folder resolves outside that folder or dangles, under the shared link grammar; (3) each marketplace entry's declared `./skills/<name>` set equals the sorted on-disk inventory of its source, the `han` meta entry declares none, and no package `.claude-plugin/plugin.json` declares `skills`; (4) no skill `.md` file contains `CLAUDE_PLUGIN_ROOT`; (5) no configuration-home literal (`~/.claude`, `$HOME/.claude`, `${HOME}/.claude`) appears outside the pinned portable line; (6) the discovery inputs list exactly the intended set, 45 plugin skills plus the 2 marked-internal repo skills, with the byte-exact marker on exactly those 2; (7) vendored rule copies are byte-identical to their canonical files at both the package level and the skill level; (8) the README names both install channels, the CLI's update command, and the internal-skills opt-in; (9) no skill `.md` file contains `CLAUDE_SKILL_DIR`. The guard inherits the Codex test's portability constraints (bash 3.2; grep one named file, never `-r`) and parses the marketplace JSON with Node, comparing sets.
- **Rationale:** Each assertion maps to a spec release-guard row that fails before release. The name-equals-folder assertion goes beyond spec D7's literal list on purpose: the agent-skills specification requires the name to match the parent directory, and T2 makes the folder the installed identity. The skill-dir assertion guards the eighth rewrite class (spec D10) the same way assertion 4 guards the plugin-root rewrite. The assertions are grammar-level (awk line extraction, `sort | uniq -d`, `cmp -s`, Node JSON parsing), not byte-greps of Prettier's formatting.
- **Evidence:** Spec D7 and the spec's release-guard table; test-engineer §2.3 (grammars and assertion list); structural-analyst §5 (assertion list); `.discovery-notes.md` (agent-skills specification pins: `name` must match the parent directory); `test/codex-packaging.bats` header (portability constraints).
- **Rejected alternatives:**
  - A narrower list without the name-equals-folder assertion — rejected; the folder is the installed identity (T2), and the agent-skills specification requires the match.
  - A broader list with the YAGNI-deferred static lints (dispatch disclosure wording, reference normalization, standalone-block presence, namespaced skill references) — rejected; brittle, and agent references share the namespaced shape (claim C5, deferred with triggers).
  - A list without the skill-dir assertion — rejected; the eighth rewrite class is committed (spec D10), and the guard owns its invariants.
- **Specialist owner:** test-engineer
- **Revisit criterion:** A deferred static lint's reopening trigger fires: a shipped skill references a nonexistent skill name, users report a missing substitution note, a channel install's dispatch step silently fails, or a namespaced skill reference ships and breaks a partial install.
- **Dissent (if any):** —
- **Driven by rounds:** R1; operator input 2026-10-16 (assertion 9)
- **Dependent decisions:** D-13
- **Referenced in plan:** Implementation Approach (The packaging guard and its assertions), Work Units and Sequencing (WU-7), Definition of Done

### D-6: One-time migration codemod

- **Question:** How is the 47-skill rewrite delivered, and does the rewrite machinery stay in the repo?
- **Decision:** A one-time codemod with named passes and a `--dry-run` diff mode delivers the rewrite, so the 47-skill diff is reviewable pass by pass and reproducible. The codemod is not retained in the tree after the migration; the packaging guard owns the invariants afterward.
- **Rationale:** The rewrite spans 47 skills and roughly 184 links plus the configuration-resolution, dispatch, and reference passes. Hand edits per skill leave no review story, and a retained codemod is machinery without a second use.
- **Evidence:** Structural-analyst §4 (rewrite classes with measured scope and mechanical handles); measured: 148 `SKILL.md` links across 45 skills, 32 references-file links across 6 skills, 4 special links; test-engineer Finding 3.
- **Rejected alternatives:**
  - Hand edits per skill — rejected; no review story across 47 skills.
  - A retained codemod — rejected; one-time use (YAGNI-deferred; reopens when the CLI's install contract changes or a second corpus-wide rewrite is needed).
- **Specialist owner:** structural-analyst
- **Revisit criterion:** The CLI's install contract changes (T2), or a second corpus-wide rewrite is needed.
- **Dissent (if any):** —
- **Driven by rounds:** R1
- **Dependent decisions:** —
- **Referenced in plan:** Implementation Approach (Vendored copies and rewritten links), Work Units and Sequencing (WU-3), Risks and Assumptions (R3)

### D-7: Discovery-set verification without invoking the CLI

- **Question:** How is the CLI's discovery of the repo verified, given the guard must not depend on the network?
- **Decision:** The guard verifies discovery as an in-repo proxy: assertions 3 and 6, plus the marker half of 6, pin the discovery inputs (manifest declared skills equal disk, the `.claude/skills/` container holds exactly the two repo skills, the byte-exact marker sits on exactly those two). The CLI-facing checks — the real listing output and grouping, a sandbox install's self-containment, a local marketplace install loading each skill exactly once — run as a maintainer end-to-end pass at release. The guard never invokes the CLI.
- **Rationale:** Invoking the CLI in CI is network-dependent, version-drifting, and slow, and the in-repo proxy covers the failure modes the guard exists for. The presentation layer (list grouping, dedupe order) is not auditable from this repo; the e2e covers it at release (claim C6).
- **Evidence:** Test-engineer §3 and §5 (what is testable where), Finding 4 (YAGNI candidate), Finding 8 (Unverified CLI-side); `.discovery-notes.md` (Gaps; CLI contract pins).
- **Rejected alternatives:**
  - Invoking the CLI inside the guard or CI — rejected; network-dependent, version drift, slow; deferred with a reopening trigger (the CLI shipping an offline or dry-run discovery mode, or a compatibility bug shipping to the channel).
- **Specialist owner:** test-engineer
- **Revisit criterion:** The CLI ships an offline or dry-run discovery mode, or a compatibility bug ships to the channel.
- **Dissent (if any):** —
- **Driven by rounds:** R1
- **Dependent decisions:** —
- **Referenced in plan:** Implementation Approach (The packaging guard and its assertions), Testing Strategy, Definition of Done

### D-8: Work-unit sequencing and the same-change constraint

- **Question:** In what order do the work units land, and which changes must ship together?
- **Decision:** Nine work units in this order: WU-1 (internal marker), WU-2 (sync machinery), WU-3 (vendored copies and link rewrites), WU-4 (portable configuration resolution), WU-5 (dispatch substitution and cross-skill references), WU-6 (manifest arrays), WU-9 (skill-root-relative references), WU-8 (README), then WU-7 (the guard). WU-2 precedes WU-3 (the sync produces the vendored copies the rewrite points at). WU-4, WU-5, and WU-9 run after WU-3 because they edit the same skill files. WU-7 depends on WU-1, WU-2, WU-3, WU-4, WU-6, WU-8, and WU-9, because the guard's README assertion requires the both-channels section to exist and assertion 9 requires the skill-dir rewrite to have landed. The same-change constraint (claim C1): the D-4 rewrite and the `scripts/han-config-dir.bats` surgery land in one change, or the suite goes red, because the test pins the old probe/grant pattern byte for byte.
- **Rationale:** Each ordering rule exists because splitting the pair leaves a red suite or a dangling reference: the Bats file pins the pattern the rewrite removes, and the guard asserts README content that the README work unit writes.
- **Evidence:** Claim C1 (R1, TE-1 and SA-F-S3; evidenced: `scripts/han-config-dir.bats` pins the GRANT/PROBE literals byte for byte, 90 probe/grant lines measured); R2's C1 resolution (evidence plus sequencing); the merged assertion list (assertion 8, README).
- **Rejected alternatives:**
  - Separate changes for the D-4 rewrite and the `han-config-dir.bats` surgery — rejected; the suite goes red between them (claim C1).
  - The guard before the README — rejected; assertion 8 fails until the both-channels section exists.
- **Specialist owner:** plan-synthesizer
- **Revisit criterion:** A rewrite and its pinning test separate, or the guard's assertion set changes shape.
- **Dissent (if any):** —
- **Driven by rounds:** R2; synthesis (Step 8 evidence) — the guard's README assertion makes WU-8 a dependency of WU-7; operator input 2026-10-16 (WU-9 added)
- **Dependent decisions:** —
- **Referenced in plan:** Work Units and Sequencing

### D-9: Manifest array shape and guard parsing

- **Question:** What shape do the marketplace `skills` arrays take, and how does the guard check them given Prettier owns the JSON bytes?
- **Decision:** All 13 `han-*` entries in `.claude-plugin/marketplace.json` gain `"skills": ["./skills/<name>", ...]`, path strings relative to the entry's `source`, written in Prettier's expanded shape (newline after `[`, one path per line). The `han` meta entry gains none, because `han/` ships no `skills/` folder. The guard parses the manifest with Node (available wherever `npm test` runs; the Bats bin is a Node script) and compares sets; it never byte-matches the arrays.
- **Rationale:** Declared skills are the CLI's documented discovery contract and produce the grouped listing (spec D6, T1). Prettier owns the JSON bytes, so byte-grepping the arrays would couple the guard to Prettier's formatting; set comparison is stable. In the plugin channel the entry declaration is appended to the plugin's own manifest under strict mode, so the declaration must be a pure restatement of the conventional inventory: the guard's assertion 3 proves it, and a local marketplace install at release confirms no double-load (T4).
- **Evidence:** `.discovery-notes.md` (CLI contract pins: manifest skills declaration; Prettier owns md/json/yaml/js); structural-analyst §5 (worked example in Prettier's expanded shape; `han/.claude-plugin/plugin.json`'s `dependencies` array as shape evidence); measured: all 13 package `plugin.json` files declare no `skills` key today; test-engineer grammar 1.
- **Rejected alternatives:**
  - Byte-grep shape assumptions — rejected; Prettier's formatting is not a contract the guard should own.
  - Declaring skills in each package's own `plugin.json` — rejected; the CLI reads only root manifests, so it would not affect the channel (spec D6's own rejection).
- **Specialist owner:** structural-analyst
- **Revisit criterion:** Prettier changes the array formatting in a way that breaks the guard's parsing, or the manifest gains a shape that Node set comparison cannot check.
- **Dissent (if any):** —
- **Driven by rounds:** R1
- **Dependent decisions:** D-5, D-7
- **Referenced in plan:** Implementation Approach (Manifest skills declarations), Work Units and Sequencing (WU-6)

### D-10: The han-config-dir script and its test

- **Question:** What happens to `scripts/han-config-dir.sh` and `scripts/han-config-dir.bats` when the probe pattern is rewritten away?
- **Decision:** The script stays: the plugin channel ships it (symlinked into every plugin except `han`), and the plugin channel is unchanged. The test is repurposed: the probe/grant pairing tests retire (superseded by the guard's plugin-root and configuration-home assertions), the resolver-behavior tests stay (they pin the semantics the inlined line replicates: the resolution order, the unreadable-versus-absent distinction, the fallback), the script-exists test stays, and a new test pins the portable line byte-identically in every plugin skill. The surgery lands in the same change as the D-4 rewrite (D-8).
- **Rationale:** The test pins the GRANT/PROBE literals byte for byte, so it goes red the moment the rewrite lands. Retiring the pairing tests and pinning the new line keeps the suite's coverage of the resolution semantics without pinning a removed pattern.
- **Evidence:** Test-engineer Finding 1 (coordination, blocking); structural-analyst §4 (same-migration updates); `scripts/han-config-dir.bats` read in full (R2 input); measured: 90 probe/grant lines across the 45 plugin skills.
- **Rejected alternatives:**
  - Deleting the script — rejected; the plugin channel still ships the shared scripts.
  - Leaving the test stale — rejected; the suite goes red (claim C1).
- **Specialist owner:** test-engineer
- **Revisit criterion:** The plugin channel stops shipping the shared scripts, or the resolution semantics change.
- **Dissent (if any):** —
- **Driven by rounds:** R1
- **Dependent decisions:** D-8
- **Referenced in plan:** Implementation Approach (Portable configuration resolution), Work Units and Sequencing (WU-4), Testing Strategy

### D-13: Eighth rewrite class — skill-root-relative references

- **Question:** How do skills that invoke their bundled scripts or read their bundled files reference them over the channel?
- **Decision:** Every `${CLAUDE_SKILL_DIR}` path reference in shipped skill content is rewritten to a skill-root-relative path: `${CLAUDE_SKILL_DIR}/scripts/foo.sh` becomes `scripts/foo.sh`, and `${CLAUDE_SKILL_DIR}/references/x.md` becomes `references/x.md`. The packaging guard asserts no skill `.md` file contains `CLAUDE_SKILL_DIR` (assertion 9). The vendored guidance corpus copies carry the rewritten references on the next sync run.
- **Rationale:** The variable is a Claude Code built-in; the agent-skills specification defines no skill-path variable and prescribes skill-root-relative paths for referencing bundled files. Leaving the references would break script steps on the agents that do not define the variable.
- **Evidence:** Operator decision, 2026-10-16 ("this is an eighth rewrite class and we should do it as part of this work"). Agent-skills specification, file-references section (fetched 2026-10-16). Repo sweep: 57 reference sites across the skill folders (28 in `SKILL.md` files across 15 skills; 30 script invocations, 36 file reads, 9 carrying both; none inside command-substitution probes). Spec D10 and T6.
- **Rejected alternatives:**
  - Leave the references and accept degraded script steps on agents that do not define the variable — rejected by the operator.
  - Rewrite to per-agent variables — rejected; the agent-skills specification defines no standard skill-path variable, so there is nothing portable to target.
  - Inline the script contents into the skill instructions — rejected; it discards the bundled script files the CLI installs.
- **Specialist owner:** structural-analyst
- **Revisit criterion:** A release e2e or user report shows a target agent's shell does not resolve skill-root-relative script paths.
- **Dissent (if any):** —
- **Driven by rounds:** R2 (OQ-1); operator input 2026-10-16
- **Dependent decisions:** D-5 (assertion 9), D-8 (sequencing)
- **Referenced in plan:** Implementation Approach (Skill-root-relative references), Work Units and Sequencing (WU-9), Testing Strategy, Risks and Assumptions

### D-15: Guard file scope — every markdown file inside a skill folder

- **Question:** Do the packaging guard's file-scoped assertions (4, 5, and by extension 9) read "skill `.md` file" as each skill's `SKILL.md` alone, or as every `.md` file inside a skill folder, including vendored rule copies and the guidance corpus?
- **Decision:** Every `.md` file inside a skill folder, for assertions 4, 5, and 9 alike. The rewrite therefore purges `CLAUDE_PLUGIN_ROOT` from 12 guidance-corpus `.md` files (4 canonicals in `guidance` plus their `skill-builder`/`agent-builder` copies), configuration-home literals from canonical `config-rule.md` and its 57 managed copies, and the same literals from three skill bodies (`han-feedback`, `iterative-plan-review`, `issue-triage`), re-syncing all copies to the 223-row fixed point. Assertion 5 whitelists exactly one carrier: lines byte-identical to the pinned portable line.
- **Rationale:** Matches assertion 2's established grammar ("any `.md` file inside a skill folder") and closes the drift channel the W-3 vendoring opened: a copy is shipped content, whatever its origin. Spec D7's release-guard rows target shipped instruction surfaces; the corpus rides the skills channel and ships identically.
- **Evidence:** Operator ruling 2026-10-19 at the W-4 negotiation the handoff pre-authorized ("Expect to negotiate", handoff §W-4). Measured at W-4 tip: 45 `SKILL.md` probe lines; 12 corpus `.md` files naming the plugin root; 45 in-folder `config-rule.md` copies plus 18 corpus files carrying a configuration-home literal; 16 body literals across three skills. The two `.claude` repo-maintenance skills measured clean of both classes.
- **Rejected alternatives:**
  - Scope the assertions to `SKILL.md` files only — rejected by the operator; vendored copies would remain unguarded shipped content.
  - Keep the measured probe-form table and verbatim error quotes literal and exempt the corpus — rejected; it is the same exemption by another name, and it leaves assertion 5 red.
- **Specialist owner:** — (operator decision at the W-4 gate)
- **Revisit criterion:** W-9's assertion 2 dangling-clause negotiation (the 142-placeholder caveat) reopening corpus scope, or a channel-install report showing corpus literals surviving.
- **Dissent (if any):** —
- **Driven by rounds:** operator input 2026-10-19 (W-4 flag)
- **Dependent decisions:** D-5 (assertions 4, 5), D-10 (supersession of the probe/grant tests), D-16, D-17
- **Referenced in plan:** Implementation Approach (Portable configuration resolution, The packaging guard and its assertions)
- D-22: W-9 dangling-link exclusion design and the broken fixture (2026-10-19) — assertion 2's dangling clause checks existence only for links resolving to the shipped-content shapes inside a skill folder (`references/**`, `scripts/**`, `assets/**`, root `SKILL.md`), and skips two classes measured at exactly 142 links: scaffold files whose content is copied into the user's tree (`*-template.md`, `template.md`, `work-items-file-format.md`, anything under `templates/` or `assets/`) and placeholder/destination-layout targets (`{curly}`/`[bracket]`/`<angle>`/`...` examples; `docs/…`, `artifacts/…`, `.claude/…`, instantiation siblings) — those are contracts of the destination repository, not of the shipped folder; a genuine regression (F6's missing linked rule file) can only appear in the checked shapes. The link walker was extracted into one shared `md_link_targets` after the second consumer appeared, keeping the guard's grammar single-sourced, and every check takes a root argument. The "observed failing" criterion is recorded permanently as one composite fixture violating all nine assertions at once (each check must bite), and was additionally observed live during W-9 by injecting the forbidden patterns into a real skill, watching the three variable/home guards turn the suite red, and reverting. The discovery-shape test that completes this also lands W-1's deferred box (45 plugin + 2 internal), which is ticked here. Driven by: W-9. Dependent decisions: D-5, spec D7.
