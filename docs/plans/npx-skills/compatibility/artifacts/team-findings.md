# Team Findings: npx skills compatibility for Han

Behavioral outcomes live in [../feature-specification.md](../feature-specification.md). Decisions the findings affect live in [decision-log.md](decision-log.md). Load-bearing mechanics live in [feature-technical-notes.md](feature-technical-notes.md). The review round has returned: two reviewers produced 30 raw findings, merged into the 18 records below. The han-core roster agents were not dispatchable in this session, so the reviewers ran as general-purpose agents briefed into the junior-developer (fresh-eyes) and on-call-engineer (resilience) roles; the role each finding came from is named on the finding. The plan-synthesizer role likewise ran as a general-purpose agent; it returned an empty report on two dispatches, so the drafter performed the synthesis pass directly per artifact-invariants.md: every decision D1-D9 is classified full (recorded in [decision-log.md](decision-log.md)), and the cross-reference invariants were verified by hand. The readability-editor role also returned an empty report, so the drafter ran the readability rule's standardized self-check over the spec's prose regions directly and corrected its failures (two unexplained terms given half-sentence glosses, one over-length sentence split), per the fallback in plan-a-feature Step 8.5.

## Major findings

### F1: The channel delta names components the plugin does not ship

- **Agent:** on-call-engineer role (via general-purpose agent); also raised by the fresh-eyes reviewer
- **Reviewer identifiers:** JD-2, OC-6
- **Finding:** The spec claimed the skills channel "does not carry (specialist agents, hooks, slash commands)." Verified against the repo: no package manifest declares hooks, no package ships a commands directory, and the only hooks in the repo are git pre-commit hooks for Han's own development. In the plugin channel the skills are the slash commands. The real delta is the specialist-agent roster and the package-level shared scripts.
- **Resolution:** Corrected the delta everywhere it appeared: the preamble, Out of Scope, Cut for Scope, and User Interactions now name specialist agents and shared scripts, and D8's README commitment matches.
- **Resolved by:** evidence
- **Affected decisions:** D8
- **Affected tech-notes:** —
- **Changed in spec:** preamble, Out of Scope, Cut for Scope, User Interactions

### F2: No update story for installed copies

- **Agent:** on-call-engineer role (via general-purpose agent); also raised by the fresh-eyes reviewer
- **Reviewer identifiers:** JD-13, OC-1
- **Finding:** The spec covered list, install, and run, but never said how an installed skill is refreshed when Han ships a new version. Because vendored rule copies are a snapshot inside each installed folder, staleness is the default between releases and the user sees nothing.
- **Unverified:** The reviewers did not inspect the CLI's update commands. During resolution the drafter verified in the CLI's documentation that an update command exists and refreshes installed skills from the same source.
- **Resolution:** Added the "Updating installed skills" alternate flow and a Coordinations row for refresh; the README commitment names the update command. A proactive staleness notification is not committed: the pull-based update is the simpler version the evidence supports.
- **Resolved by:** evidence
- **Affected decisions:** D8
- **Affected tech-notes:** —
- **Changed in spec:** Alternate Flows and States, Coordinations, User Interactions

### F3: Configuration resolution is asserted portable but not specified

- **Agent:** on-call-engineer role (via general-purpose agent); also raised by the fresh-eyes reviewer
- **Reviewer identifiers:** JD-3, JD-7, OC-3
- **Finding:** "Personal-configuration resolution behaves the same as a plugin install" was undefined: the term was never explained, the per-agent resolution chain was never stated, the "cannot be resolved" failure had no remaining failure in the chain, the project-config probe conflates an unreadable file with an absent one, and on an agent that does not execute embedded command-substitution blocks the resolution never runs at all.
- **Unverified:** The per-agent matrix of which skill formats execute command-substitution blocks was not inspected (agent-side). The commitment is stated so behavior never depends on it.
- **Resolution:** D5 now defines the resolution (the project's `.han/config.md`, then the agent's override and default), commits the unreadable-versus-absent distinction, and moves the resolution into the skill's instructions. T5 records why the resolution cannot depend on agent-specific probe blocks.
- **Resolved by:** evidence
- **Affected decisions:** D5
- **Affected tech-notes:** T5
- **Changed in spec:** Primary Flow, Edge Cases and Failure Modes

### F4: Skill bodies hardcode the configuration home

- **Agent:** fresh-eyes reviewer (junior-developer role, via general-purpose agent)
- **Reviewer identifiers:** JD-4
- **Finding:** Beyond the probe pattern, skill bodies hardcode the Claude home directly (han-feedback reads and writes `~/.claude/han-feedback/`, iterative-plan-review globs `~/.claude/plans/`, issue-triage writes `$HOME/.claude/triages/`). On an agent whose configuration home is not `~/.claude`, these skills read and write the wrong locations. The Out of Scope rewrite list did not cover body paths.
- **Unverified:** The reviewer's sweep covered three skills plus the frontmatter pattern, not all 47 bodies. The packaging lint closes the gap mechanically.
- **Resolution:** The rewrite scope now includes hardcoded configuration-home paths, D5 forbids them, and the packaging check fails on any skill body that hardcodes the configuration home.
- **Resolved by:** evidence
- **Affected decisions:** D5, D7
- **Affected tech-notes:** —
- **Changed in spec:** Out of Scope, Edge Cases and Failure Modes

### F5: The Outcome omits the channel's real deltas

- **Agent:** fresh-eyes reviewer (junior-developer role, via general-purpose agent)
- **Reviewer identifiers:** JD-1, JD-15
- **Finding:** The Outcome promised skills "run correctly" while admitting only one degradation (agent dispatch) and deferring the rest to a README the spec only summarized. It never stated that no specialist agents ship, never named the quality trade-off of inline substitution, and never told the developer that the listing shows 45 while 47 are installable — the opt-in for the two maintenance skills appeared only in a technical note.
- **Resolution:** The Outcome now states what the channel carries (skills only), names the substitution trade-off, and gives the 45-plus-opt-in shape. The opt-in is surfaced in Primary Flow step 1 and User Interactions.
- **Resolved by:** evidence
- **Affected decisions:** —
- **Affected tech-notes:** —
- **Changed in spec:** Outcome, Primary Flow, User Interactions

### F8: The partial-install promise has no mechanism and no end state

- **Agent:** on-call-engineer role (via general-purpose agent); also raised by the fresh-eyes reviewer
- **Reviewer identifiers:** JD-9, OC-2, OC-5
- **Finding:** "Named, and the run continues" committed to no mechanism (grounding is uneven across skills), no end-of-run signal for omitted work, and no behavior for a thin orchestrator whose every part needs the missing skill.
- **Unverified:** How each agent surfaces a failed skill invocation is agent-side and was not audited. The commitment is stated at the skill level.
- **Resolution:** D9 now commits: the missing skill is named at the point of use, the run stops with the skill to install when no part can proceed, and a partial run ends with an omissions summary. The rewrite scope gains missing-reference handling.
- **Resolved by:** evidence
- **Affected decisions:** D9
- **Affected tech-notes:** —
- **Changed in spec:** Alternate Flows and States, Out of Scope

## Minor edits

- F6: The missing-rule-file row was unreachable under the spec's own guarantees and its "pause" behavior was undefined — redefined for corrupted or partial installs as "name the file and stop before acting on it" — fresh-eyes and on-call-engineer roles — Edge Cases and Failure Modes.
- F7: The failure table mixed developer-runtime rows with maintainer release-guard rows — split into two tables — fresh-eyes and on-call-engineer roles — Edge Cases and Failure Modes.
- F9: Cross-references appear in three forms (plain, namespaced, slash-command syntax) but the spec committed only to plain names — D9 extended to normalize the other forms in the rewrites — fresh-eyes role — Out of Scope.
- F10: "The compatibility work is inert" in the plugin channel was an assumption, not a behavior — reworded as an enforced invariant (both channels read the same folders; the packaging check keeps copies identical) — fresh-eyes role — Alternate Flows and States.
- F11: The substitution note's audience, frequency, and quality disclosure were unstated — committed: once per run, at the first substitution, naming the substitution and the loss of independent review — fresh-eyes and on-call-engineer roles — Primary Flow, Alternate Flows and States.
- F12: Preconditions named no supported-agent list and presumed a "today" that does not exist for non-plugin agents — preconditions point to the CLI's documentation; integration needs are stated by the skill when invoked — fresh-eyes role — Actors and Triggers.
- F13: The headline command's resolution mechanism was unstated — OI-1 now states the command resolves the repository directly from its GitHub source — fresh-eyes role — Open Items.
- F14: Behavioral sections used implementation vocabulary (setup probes, vendored copies, manifest restatement) — reworded in behavioral terms — fresh-eyes and on-call-engineer roles — Primary Flow, Alternate Flows and States, Coordinations.
- F15: Coexistence of both channels on one agent was unaddressed — the README advises one channel per agent; agent-side precedence is the agent's own (unverified agent-side) — on-call-engineer role — Edge Cases and Failure Modes, User Interactions.
- F16: The permission-declaration degradation (per-call approval prompts) was named nowhere user-facing — added to Feedback and the README commitment — on-call-engineer role — User Interactions.
- F17: No behavior for running a maintenance skill outside the Han repository — D4 gains the stop behavior — on-call-engineer role — Alternate Flows and States.
- F18: The Summary shipped review-round placeholders — filled after the review round — fresh-eyes role — Summary.

## Unaudited evidence classes

- Agent-side skill-runtime behaviors: which skill-file features each supported agent executes (command-substitution probes), how slash-command syntax maps to installed skills, and how an agent resolves duplicate skill names across install locations. No reviewer could audit these; they live in agent documentation, not this repo. The spec commits only skill-level behavior for them (D5, D8, D9).

## Escalation register

### E1: Where the plan lives, and the direction of travel

- **Answer:** "Put it in docs/plans/npx-skills/compatibility, but in the ~/src/han directory." And: add `npx skills` as a second channel; the plugin stays the full install.
- **Landed in:** [scope-boundary.md](scope-boundary.md) (Operator-Stated Scope, Direction of Travel); the channel-scope context for D1 in [decision-log.md](decision-log.md).

### E2: The four scoping questions (channel scope, agent degradation, rule-file vendoring, maintenance skills)

- **Answer:** All 47 skills. "Can it just run the skill without the specific agent?" Vendor a copy into each skill and rewrite the links. Hide the maintenance skills from the public listing.
- **Landed in:** D1, D2, D3, and D4 in [decision-log.md](decision-log.md); Primary Flow, Alternate Flows and States, and Edge Cases and Failure Modes in [../feature-specification.md](../feature-specification.md).

No Step-7 escalations: all 18 findings resolved from evidence; none required the operator's judgment.
