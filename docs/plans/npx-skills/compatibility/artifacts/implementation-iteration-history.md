# Implementation Iteration History: npx skills compatibility for Han

This file records how the implementation plan for npx skills compatibility for Han evolved across
discussion rounds. Committed decisions live in
[implementation-decision-log.md](implementation-decision-log.md) and the primary plan lives in
[../feature-implementation-plan.md](../feature-implementation-plan.md).

Provenance notes for this run:

- The operator directed the run to proceed without requesting permission, so the Step 1.5
  confirmation turn was skipped. The recorded boundary stands as read: purely additive second
  install channel, plugin channel unchanged, plan in `docs/plans/npx-skills/compatibility/`
  (see [scope-boundary.md](scope-boundary.md)).
- The han-core roster agents are not dispatchable in this session, so specialists ran as
  general-purpose agents briefed into their roles — the same precedent the spec stage recorded in
  its team-findings.md.
- Team size: medium (2 chosen specialists plus the always-present junior-developer and
  plan-synthesizer), per team-selection.md — three subsystems (the 47-skill corpus rewrite; the
  marketplace manifest, packaging guard, and CI; the README) plus an inbound third-party
  integration (the CLI's manifest contract). Round cap: 2.

## R1: Parallel specialist review

- **Specialists engaged:** test-engineer (han-core:test-engineer role, via general-purpose agent,
  session ses_ebac893afffeSmnUZS2JEoNuFi); structural-analyst (han-core:structural-analyst role, via
  general-purpose agent, session ses_ebac88e0bffeScsgfAqxDEEJsn).
- **New input provided:** initial feature specification and discovery notes
  ([.discovery-notes.md](.discovery-notes.md)), including the fetched CLI contract pins and the
  measured figures.
- **Claim ledger:**
  - C1 (coordination, sequencing-blocking) — The D5 probe rewrite and the `scripts/han-config-dir.bats`
    rewrite must land in the same change or the suite goes red; repurpose han-config-dir.bats to pin
    the new portable line byte-identically; keep the script and its symlinks (the plugin channel
    still ships them). — TE-1, SA-F-S3 — Evidenced (`scripts/han-config-dir.bats` pins the GRANT/PROBE
    literals byte for byte; 90 probe/grant lines measured).
  - C2 (guard scope) — The link guard must scan all `.md` files in skill folders, not just
    `SKILL.md` (232 escaping link occurrences across skill `.md` files vs ~150 in `SKILL.md` alone);
    the shared link grammar skips fenced code blocks and inline code spans. — TE-2, SA §2 —
    Evidenced (measured).
  - C3 (rewrite special cases) — Four escaping links in 2 skills are not the mechanical rule-file
    pattern (han-release ×2, iterative-plan-review ×1 in `SKILL.md`, plus
    han-release/references/changelog-rules.md ×1) and are handled by the link-derived vendoring plus
    a per-link rewrite; one code-span artifact (iterative-plan-review `SKILL.md:63`) needs the
    grammar's code-span skip. — TE-3, SA §2 — Evidenced (measured).
  - C4 (sync canonical source) — Disputed: TE proposed a sort-derived canonical (first sorted
    package-level copy per basename); SA proposed an explicit canonical map naming per-file owners.
    Settled by evidence in R2: explicit map (see R2). — TE-7, SA §1/F-S2 — Disputed in R1.
  - C5 (YAGNI candidates) — Invoking the CLI inside the guard/CI (TE-4); a YAML parser dependency
    (TE-5); static lints for D2's disclosure wording, D9's reference normalization, standalone-block
    presence, and namespaced skill references (TE-6 + SA-F-S4); retaining the migration codemod
    (SA-F-S4); an npm `sync` script entry (SA); a `--check` mode on the sync script (SA). —
    Evidenced; dispositions in the YAGNI sweep ledger below.
  - C6 (Unverified, CLI-side) — CLI list grouping and dedupe order beyond the fetched README pins
    are not auditable from this repo; the guard pins the discovery set, not the presentation. — TE-8
    — Unverified; disposition: not reachable with granted tools; maintainer e2e covers it at release.
  - C7 (Unverified, agent-side) — Whether the sanctioned resolution line names every supported
    agent's override variable is agent-side; the guard pins structure, not per-agent correctness. —
    TE-9 — Unverified; disposition: not reachable with granted tools.
  - C8 (note) — Package-level vendored copies without skill readers (han-ddd's `evidence-rule.md`
    and `yagni-rule.md`, han-research's `yagni-rule.md`) stay synced in place; retirement is a
    separate operator decision, not part of this feature. — SA-F-S5 — Evidenced (measured);
    Unverified sub-claim: whether long-form docs link them was not swept.
  - C9 (spec-level, became OQ-1) — Per-skill script invocation portability: `${CLAUDE_SKILL_DIR}` is
    referenced by 28 lines in `SKILL.md` files across 15 skills (broader sweep: 57 lines across skill
    folders; 30 invoke `/scripts/`, 36 read `/references/`, 9 carry both; none inside `!`…`` probes).
    The spec's committed rewrite list (Out of Scope) names seven classes and does not include
    skill-dir variable rewrites; the failure-mode tables have no row for it. — SA-F-S1 — spec-level.
  - C10 (agreement, no finding) — Both specialists independently committed to: the guard at
    `test/skills-packaging.bats`; one repo-root sync script with its bats beside it; bash 3.2
    portability, grep-one-named-file, Prettier byte-format awareness; manifest `skills` arrays on all
    13 `han-*` entries and none on the `han` meta entry; the byte-exact internal marker on exactly
    the 2 repo skills; the pinned portable resolution line as instruction text per T5. (The sync
    script's name differed — `sync-vendored-rules.sh` vs `sync-vendored-files.sh`; the plan picks one.)
- **Open Questions raised:** OQ-1 (from C9, spec-level): on an agent that does not define
  `CLAUDE_SKILL_DIR`, do the affected skills' script steps break, degrade, or still work — and does
  the compatibility work add an eighth rewrite class or not?
- **Spec-maturity tags:** spec-level: 1 (OQ-1, raised by 1 specialist). T#-contradiction: 0 (both
  specialists returned Confirm on T1-T5). plan-level: the remainder. Gate: NOT tripped (the gate needs
  ≥2 T#-contradictions from ≥2 specialists, or ≥5 spec-level findings from ≥3 specialists).
- **Contract pinning:** Y — the round's committed contracts carry concrete forms: the internal-marker
  frontmatter bytes plus `INSTALL_INTERNAL_SKILLS` (fetched CLI README); the manifest skills-array
  shape with a Prettier-expanded worked example; the vendored-copy location contract
  `{skill}/references/<basename>` with the rewritten link forms; the sync `--list` contract
  (`canonical_path<TAB>destination_path`, repo-relative, LF, sorted, no header); the pinned portable
  resolution line (worked example adopted as exact bytes); the guard assertion list; the discovery-set
  shape (45 public + 2 internal = 47).
- **Resolution source:** — (R1 raised the questions; resolutions recorded in R2)
- **Decisions produced:** D-1, D-2 (raised with the canonical-source dispute C4 open), D-3, D-4, D-5,
  D-6, D-7, D-9, D-10, D-12 — drafted from the test-engineer and structural-analyst reports. D-11 was
  recorded but not settled (the two specialists proposed different sync-script names, C10); D-8 was not
  yet raised (sequencing followed from C1 in R2 and the synthesis pass).
- **Changed in plan:** Implementation Approach (guard and assertions, sync machinery, vendored-copy
  contract, portable resolution line, manifest shape); Work Units and Sequencing (WU-2, WU-3, WU-4,
  WU-7); Testing Strategy; Risks and Assumptions (R1–R3, R5); Deferred (YAGNI) (the C5 candidates).
- **Next-step recommendation:** continue iterating — settle the C4 dispute by evidence and process
  OQ-1 (evidence, then junior-developer reframing, then defer per the operator's directive).

## R2: Resolution round (evidence and reframing; no further specialist review dispatched)

- **Specialists engaged:** junior-developer (han-core:junior-developer role, via general-purpose
  agent, session ses_ebaa94ca4ffeGBlqiX7tmOwfZI) for the OQ-1 reframing. Neither R1 specialist named
  another specialist as a needed handoff, so no further specialist review was dispatched.
- **New input provided:** repo-side verification (canonical-owner self-descriptions; the
  `${CLAUDE_SKILL_DIR}` sweep and classification; the tdd `SKILL.md` Project Context block;
  `scripts/han-config-dir.bats` read in full) and one fetched standard: the agent-skills
  specification (agentskills.io/specification, pins recorded in .discovery-notes.md).
- **Claim ledger (updated):**
  - C4 settled — explicit canonical map. Evidence: `han-core/references/config-rule.md:17` and
    `collaborative-stop-rule.md:20` name han-core as canonical; CLAUDE.md's Configuration and
    writing-voice sections name han-core (config/evidence/YAGNI rules) and han-communication
    (readability/writing-voice/explanation rules) as canonical owners; han-planning's references are
    self-described as owned. A sort-derived canonical would mislabel `config-rule.md` (first sorted
    copy is han-atlassian's). The sync map names one canonical owner per file.
  - C9 sharpened by the reframing into eight clarifying questions, of which the repo-side ones are
    now answered (see .discovery-notes.md, R2 addendum): the references split into script invocations
    vs file reads (30 vs 36 lines, 9 both); the agent-skills specification defines no skill-path
    variable and prescribes skill-root-relative paths for referencing bundled files; `name` must
    match the parent directory (corroborating the guard's name==folder assertion). The agent-side fork
    (what each target agent expands) remains runtime-only.
  - C1, C2, C3, C5, C6, C7, C8, C10 stand as recorded in R1.
- **Open Questions raised:** none new. OQ-1 disposition below.
- **Spec-maturity tags:** unchanged: 1 spec-level (OQ-1), 0 T#-contradiction. Gate remains untripped.
- **Contract pinning:** Y (see R1; the resolution line's worked example is adopted as the pinned bytes
  in the decision log).
- **Resolution source:**
  - OQ-1: junior-developer reframing plus evidence (agent-skills specification; repo sweep). NOT
    resolved into a committed behavior: adding an eighth rewrite class is a behavioral decision the
    spec never committed (spec-level), and the operator directed this run to proceed without
    requesting permission, so the question is deferred per Step 7 and ships as plan Open Item OI-2,
    with the standards-grounded candidate named (skill-root-relative paths per the agent-skills
    specification's file-reference convention) and a falsifiable resolution condition. Escalation
    declined per the operator's directive.
  - C4: evidence (rule-file self-descriptions and CLAUDE.md's canonical-owner map).
  - C1: evidence plus sequencing (the plan places the D5 rewrite and the han-config-dir.bats surgery
    in the same work unit).
  - C5: YAGNI sweep dispositions (ledger below).
  - Sequencing correction settled by the plan-synthesizer's own re-reading of the merged assertion
    list against the work-unit shape — synthesis (Step 8 evidence): the guard's README assertion
    (assertion 8) makes the README work unit (WU-8) a dependency of the guard (WU-7). Recorded in
    [D-8](implementation-decision-log.md#d-8-work-unit-sequencing-and-the-same-change-constraint) and
    in the plan's Work Units and Sequencing.
- **Decisions produced:** D-2 (settled — explicit canonical map; C4 resolved by evidence), D-4 (the
  pinned line's worked example adopted as exact bytes), D-8 (work-unit sequencing with the C1
  same-change constraint), D-11 (settled at synthesis from C10's recorded naming difference — the
  plan picks `scripts/sync-vendored-files.sh`). OQ-1 produced no decision: deferred per the
  operator's directive and shipped as plan Open Item OI-2.
- **Changed in plan:** Implementation Approach (canonical-owner map; pinned resolution-line bytes);
  Work Units and Sequencing (the same-change constraint; WU-4's shape); Open Items (OI-2); Risks
  and Assumptions (R1 tied to OI-2; A4); Deferred (YAGNI) (ledger finalized).
- **Next-step recommendation:** go to synthesis.

## YAGNI sweep ledger (Step 7.5)

Scope gate: no additional cuts. Every plan work unit descends from a spec commitment (D1-D9) or the
recorded boundary; the spec's own Cut for Scope (shipping specialist agents and shared scripts over
the skills channel) is inherited into the plan's Cut for Scope section with the boundary citation.
The floor holds: the guard, the tests, and the README are necessities of the asked-for work, not
cuts.

| Item | Gate failure | Resolution | Source |
| --- | --- | --- | --- |
| Invoking `npx skills` inside the packaging guard or CI | evidence (network-dependent, version drift, slow; the in-repo proxy covers D7's failure modes) | Deferred — reopen when the CLI ships an offline/dry-run discovery mode, or a compatibility bug ships to the channel | TE-4 (R1, C5) |
| A YAML parser dependency for frontmatter/manifest parsing | simpler-version (line-grammar extraction and node JSON parsing cover the pinned shapes) | Deferred — reopen when frontmatter gains nested keys the line grammar cannot parse | TE-5 (R1, C5) |
| Static lints for D2's disclosure wording, D9's reference normalization, standalone-block presence, and namespaced skill references | evidence (brittle; agent references share the namespaced shape) | Deferred — reopen when a shipped skill references a nonexistent skill name, users report a missing substitution note, a channel install's dispatch step silently fails, or a namespaced skill reference ships and breaks a partial install | TE-6 + SA-F-S4 (R1, C5) |
| Retaining the migration codemod in the repo after the 47-skill rewrite | evidence (one-time use; the guard owns the invariants afterward) | Deferred — reopen when the CLI's install contract changes (T2) or a second corpus-wide rewrite is needed | SA-F-S4 (R1, C5) |
| An npm `sync` script entry for the sync script | simpler-version (run the script directly; CONTRIBUTING names the command) | Deferred — reopen when contributors repeatedly mis-invoke it | SA (R1, C5) |
| A `--check` mode on the sync script | simpler-version (the packaging guard checks; one checker, not two) | Deferred — reopen when someone runs the sync expecting validation | SA (R1, C5) |
| Per-skill compatibility notes matrix in the README | evidence (inherited from the spec's Deferred (YAGNI); derivable from the skills themselves; no user has asked) | Deferred — reopen when users report confusion about which behaviors need the plugin | spec Deferred (YAGNI), inherited |
| Evaluating installed skills over the skills channel | evidence (inherited from the spec's Deferred (YAGNI); Han evaluates skills in-repo today) | Deferred — reopen when a compatibility bug ships to the skills channel | spec Deferred (YAGNI), inherited |

## Unaudited evidence classes

- Agent-side skill-runtime behaviors: which skill-file features each agent executes
  (command-substitution probes), how slash-command syntax maps to installed skills, and how an agent
  resolves duplicate skill names across install locations. No specialist received these; they live in
  agent documentation, not this repo. The plan commits only skill-level behavior for them (D5, D8,
  D9). The skill-dir variable question is resolved as the eighth rewrite class (spec D10); whether
  target agents' shells resolve skill-root-relative script paths remains runtime-only, verified by
  the release e2e.
- CLI-side behavior beyond the fetched README pins (npm `skills` v1.7.0, fetched 2026-10-16): exact
  list grouping output and dedupe order. C6 remains Unverified with disposition "not reachable with
  granted tools"; maintainer e2e covers it at release.

## Escalation register

No questions were escalated to the operator. The operator directed this run to proceed without
requesting permission, so the Step 1.5 confirmation turn was skipped (the recorded boundary stands
as read) and OQ-1 — the one question evidence and reframing could not settle — is deferred per Step 7
and ships as plan Open Item OI-2. Post-synthesis, the operator resolved OQ-1/OI-2 by committing the
eighth rewrite class; see the operator-input sections below.

## Step 9 check record

The first check run failed twice and was fixed before this record was written; both failures are
recorded here so the next run meets them as data:

- Contract pinning initially failed: the rewritten-link forms were written as markdown link syntax
  outside a code fence, which the check reads as a document link to a missing artifact. Fixed by
  rewording the two bullets to name the link target without the link opener; the contract is
  unchanged.
- Cross references initially failed: the trivial decisions were bolded, which the check's
  declaration patterns do not recognize. Fixed by matching the template's trivial-bullet format.

Re-run after the fixes: all three checks passed (completeness gate, contract pinning, cross
references; exit 0 each).

## Post-synthesis operator input: spec OI-1 resolved

The operator confirmed the skills directory site already lists Han, closing the spec's OI-1
("whether the skills directory site lists Han automatically or needs a submission"). Verified
2026-10-16 by fetching the site: the pack page https://www.skills.sh/testdouble/han lists all 47
skills (233 total installs, first seen Aug 5, 2026), and per-skill pages such as
https://www.skills.sh/testdouble/han/iterative-plan-review carry the install command. The
directory indexed the repository without a submission, so no submission work remains. The plan's
Open Items section drops OI-1; OI-2 remains open. Observation for the record: the directory lists
all 47 skills, including the two internal maintenance skills — the internal marker governs the
CLI's `--list` output, not the website index.

## Post-synthesis operator input: OI-2 resolved as the eighth rewrite class

The operator decided (2026-10-16): "this is an eighth rewrite class and we should do it as part of
this work." OQ-1/OI-2 is closed as committed behavior, and the artifacts were updated the same day:

- The spec now carries the eighth rewrite class: `feature-specification.md` (Primary Flow step 2,
  the Out of Scope rewrite enumeration, Open Items, Summary counts), a new decision D10
  (skill-directory path variables) in the spec's decision log, and a new technical note T6
  (skill-root-relative references). The spec's OI-1 resolution is recorded there as well.
- The plan gains work unit WU-9 (skill-root-relative references: `${CLAUDE_SKILL_DIR}/scripts/foo.sh`
  becomes `scripts/foo.sh`, `${CLAUDE_SKILL_DIR}/references/x.md` becomes `references/x.md`,
  including the vendored guidance corpus on the next sync run), guard assertion 9 (no skill `.md`
  file contains `CLAUDE_SKILL_DIR`), and a release e2e observation of a script-invoking skill on a
  non-Claude agent. Open Item OI-2 is removed; the Open Items section records both resolutions.
  Risks and Assumptions R1/A4 and the Watch after ship note are reworded: the variable dependency
  is gone, and what remains is whether target agents' shells resolve the relative form, which the
  e2e observes.
- The implementation decision log gains D-13 (eighth rewrite class — skill-root-relative
  references) and updates D-5 (assertion 9) and D-8 (WU-9 in the sequence).

The three Step 9 checks were re-run after these edits and pass.
