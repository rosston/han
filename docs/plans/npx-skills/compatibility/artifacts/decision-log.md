# Decision Log: npx skills compatibility for Han

Behavioral statements live in [../feature-specification.md](../feature-specification.md). This file captures the history, rationale, evidence, and rejected alternatives for each decision. The full/trivial split was made once, after the review round, per artifact-invariants.md: all ten decisions are full; none is trivial. D10 was added during implementation planning (2026-10-16), when the operator committed the eighth rewrite class.

## Trivial decisions

None. All nine decisions carry at least one full-decision signal — a plausible rejected alternative, evidence beyond the user's framing, a driving finding, a linked technical note, or a dependent decision — so none qualifies as trivial.

## Full decisions

### D1: Channel scope

- **Question:** Which skills does the skills channel cover?
- **Decision:** The channel covers every Han skill: all 45 plugin skills plus the 2 repo-maintenance skills. All 47 are installable; the 2 maintenance skills are hidden from the default listing (D4).
- **Rationale:** All 47 are already discovered and installable over the channel today. Excluding any would require hiding or restructuring working skills, and the reference repo ships its whole catalog.
- **Evidence:** User input ("All 47 skills"). Empirical: `npx skills add testdouble/han --list` lists 47 skills from the repo as-is, from a local clone and from the GitHub shorthand. The CLI's discovery reads the root marketplace manifest and each plugin source's skills folder (T1).
- **Rejected alternatives:**
  - A curated subset — rejected because it hides working skills and no evidence shows any skill is unfit for the channel.
  - Inclusion decided by a compatibility audit — rejected because it adds a gate that nothing fails today.
- **Linked technical notes:** T1
- **Driven by findings:** —
- **Dependent decisions:** D4, D6, D8
- **Referenced in spec:** Outcome, Primary Flow, Coordinations

### D2: Standalone degradation for agent dispatch

- **Question:** What does a skill do when a step would dispatch a specialist agent that only exists in the plugin install?
- **Decision:** The skill runs standalone. The step is performed inline by the calling model. At the first substituted step, the skill tells the developer, once, what was substituted and that the independent specialist review is replaced by the calling model's own judgment. No step hard-fails because an agent is missing.
- **Rationale:** The operator asked for exactly this ("Can it just run the skill without the specific agent?"). Failing the step would make 36 of 45 plugin skills unusable over the channel, and inlining copies of the agent prompts would drift from the canonical roster.
- **Evidence:** User input, verbatim: "Can it just run the skill without the specific agent?" Repo: 36 of 45 plugin skills reference plugin-namespaced specialist agents (31 agents across 5 packages). The CLI installs skills only; it has no mechanism for installing agents.
- **Rejected alternatives:**
  - Inline copies of the agent prompts into the skills — rejected because the copies drift from the canonical agents.
  - Document the limitation and change nothing — rejected because skills fail at the dispatch step with an unhelpful error.
- **Linked technical notes:** —
- **Driven by findings:** F11
- **Dependent decisions:** D8
- **Referenced in spec:** Primary Flow, Alternate Flows and States, Edge Cases and Failure Modes

### D3: Self-contained skills

- **Question:** How does an installed skill get the shared rule files it links to one level above its folder?
- **Decision:** Every file a skill reads at runtime lives inside the skill folder. Shared rule files are vendored into each skill that links them, the links are rewritten to the vendored copies, a sync script keeps the vendored copies identical to the canonical rule files, and the packaging check fails on any link that escapes the skill folder. The guidance corpus the authoring skills read is vendored the same way.
- **Rationale:** The CLI installs exactly one folder per skill (T2). The reference repo's skills are self-contained the same way, and Han already duplicates rule files across its 13 packages, so vendoring one level deeper matches the existing pattern.
- **Evidence:** User input ("Vendor a copy into each skill and rewrite the links"). Repo: 46 of 47 skills link to files one level above the skill folder (the config rule alone is linked 71 times, the YAGNI rule 25, the evidence rule 11, plus 5 more rule files). The same rule files are already duplicated per package (config-rule.md exists in 12 packages). A sandbox install of two skills verified the CLI copies only the skill folder, per-skill references and scripts included.
- **Rejected alternatives:**
  - Treat missing rule files as optional — rejected because skills silently skip rules they claim to follow.
  - Vendor only the most-linked rules — rejected because the long tail keeps the same failure mode.
- **Linked technical notes:** T2
- **Driven by findings:** —
- **Dependent decisions:** D7
- **Referenced in spec:** Primary Flow, Edge Cases and Failure Modes, Coordinations

### D4: Internal maintenance skills

- **Question:** Should the repo's two maintenance skills (han-release, han-update-documentation) appear in the public listing?
- **Decision:** No. They are marked internal in the skill's metadata, so the CLI hides them from the default listing; they remain installable when the installer explicitly opts into internal skills. Run outside the Han repository, either skill says it maintains Han's own repository and stops. The plugin channel and Han's own dev setup are unaffected, because agents that do not implement the marker ignore it.
- **Rationale:** The two skills maintain Han's own repo, not a user's project. The marker is the CLI's documented mechanism for exactly this case.
- **Evidence:** User input ("Hide them from the public listing"). The CLI's documentation describes the internal-skill marker and its opt-in (T3). The two skills live only in the repo's own `.claude/skills/` folder and reach the channel's discovery through that container.
- **Rejected alternatives:**
  - Leave them public — rejected because repo-internal tooling does not belong in the public catalog.
  - Relocate them out of the repo's own skills container — rejected because it breaks Han's dogfooded dev setup.
- **Linked technical notes:** T3
- **Driven by findings:** F17
- **Dependent decisions:** —
- **Referenced in spec:** Primary Flow, Alternate Flows and States

### D5: Portable configuration resolution

- **Question:** How does a skill resolve the personal configuration directory when there is no plugin root?
- **Decision:** The skill resolves it through its own instructions, the same on every supported agent: the project's `.han/config.md` first, then the personal configuration directory through the agent's own configuration-directory override and its default — the same resolution the plugin's helper script performs today. A configuration file that exists but cannot be read is named, not treated as absent. Tool-permission declarations are updated to match the portable resolution, so a plain-skill install in an agent that honors them keeps its auto-approval, and no skill body hardcodes the configuration home.
- **Rationale:** Every skill's setup probe and permission declaration depends on the plugin root today, and the plugin root does not exist after a channel install. The helper script is a one-liner, so inlining it removes the dependency without changing resolution semantics.
- **Evidence:** Repo: all 47 skills reference the plugin root, 90 of those in the config-directory probe and permission pattern. `scripts/han-config-dir.sh` prints `${CLAUDE_CONFIG_DIR:-$HOME/.claude}`. The body probes already carry a fallback to the default directory, which shows the intended semantics.
- **Rejected alternatives:**
  - Keep the plugin-root script call — rejected because it breaks or silently degrades outside the plugin.
  - Drop personal-config resolution for channel installs — rejected because it loses user configuration silently.
- **Linked technical notes:** T5
- **Driven by findings:** F3, F4
- **Dependent decisions:** D7
- **Referenced in spec:** Primary Flow, Edge Cases and Failure Modes

### D6: Explicit manifest declarations

- **Question:** Should discovery rely on the CLI's conventional layout scan, or should the marketplace manifest declare each plugin's skills?
- **Decision:** The root marketplace manifest declares each plugin's skills explicitly, as the reference repo's plugin manifest does. The channel's listing groups skills by plugin package. The declaration restates what each plugin already ships, and validation plus the packaging check must confirm the plugin channel's inventory is unchanged.
- **Rationale:** Declared skills are the CLI's documented discovery contract; the conventional scan is a fallback. Grouping matters at 45 skills. The marketplace reference confirms entries accept the skills field and that the plugin channel appends entry declarations to the plugin's own manifest under the default strict mode, so the restatement must be verified, not assumed (T4).
- **Evidence:** The CLI's documentation of plugin-manifest discovery. CLI source: discovery reads root manifest entries' declared skills and the conventional skills folder of each source, deduplicating by name. The marketplace reference: plugin entries accept every plugin.json field including skills; under strict mode the plugin's own manifest stays the authority and entry component fields are appended. The reference repo's plugin manifest declares its skills array.
- **Rejected alternatives:**
  - Rely on the conventional scan alone — rejected because it is the undocumented path and lists skills ungrouped.
  - Declare skills in each package's own manifest — rejected because the CLI reads only root manifests, so it would not affect the channel.
- **Linked technical notes:** T1, T4
- **Driven by findings:** —
- **Dependent decisions:** D7
- **Referenced in spec:** Primary Flow, Alternate Flows and States, Coordinations

### D7: Packaging guard

- **Question:** How is the compatibility contract guarded against regression?
- **Decision:** A packaging test, alongside the existing Codex packaging test, asserts on every change: every skill carries a unique name and description; no skill links outside its own folder; no skill body hardcodes the configuration home; no permission declaration depends on the plugin root; the CLI's discovery of the repo lists exactly the intended skill set; the manifest's declared skills match the packages on disk; and the vendored rule copies are identical to the canonical files.
- **Rationale:** The repo already guards its Codex packaging the same way after a real incident in which two plugins shipped uninstallable. The channel adds the same class of risk.
- **Evidence:** Repo: `test/codex-packaging.bats` guards the Codex surface and cites the incident that motivated it; `test/sanity.bats`; the pre-commit config runs checks; CI runs on a platform with Node available.
- **Rejected alternatives:**
  - Manual verification before release — rejected because the Codex incident shows it gets forgotten.
  - No guard — rejected because it accepts silent drift.
- **Linked technical notes:** —
- **Driven by findings:** F4
- **Dependent decisions:** —
- **Referenced in spec:** Edge Cases and Failure Modes, Coordinations

### D8: README documents both channels

- **Question:** How do users learn the channel exists and what it does not carry?
- **Decision:** The README documents both install channels side by side: the plugin channel (the full suite) and the skills channel (skills only). It names the CLI's update command, states what the skills channel does not carry (specialist agents, shared scripts), names the degraded behaviors (inline agent steps, per-call approval prompts on agents that ignore permission declarations), shows the opt-in for the two maintenance skills, and advises one channel per agent.
- **Rationale:** The README is where install instructions are found, and the reference repo's README shows the pattern.
- **Evidence:** Repo: README.md documents the plugin install today. Reference repo: its README shows the channel's install command.
- **Rejected alternatives:**
  - A separate docs page — rejected because the README is where install instructions are found.
  - No documentation — rejected because users discover the channel only by accident.
- **Linked technical notes:** —
- **Driven by findings:** F1, F2, F15, F16
- **Dependent decisions:** —
- **Referenced in spec:** User Interactions

### D9: Cross-skill references

- **Question:** How do skills that reference other Han skills behave over the channel?
- **Decision:** Skills reference each other by their plain skill names; namespaced and slash-command reference forms in skill bodies are normalized to plain names as part of the compatibility rewrites. The reference resolves when the referenced skill is installed alongside; otherwise the skill names the missing one at the point of use, stops with the skill to install when no part of the run can proceed, and summarizes omissions at the end of the run.
- **Rationale:** Channel installs land as sibling folders in the agent's skills directory, so plain names resolve when skills are co-installed. That is the same property the reference repo's skills rely on.
- **Evidence:** Repo: skills cross-reference by plain name in their descriptions and by plugin-namespaced name in some bodies. A sandbox install verified each skill lands as a sibling folder in the agent's skills directory.
- **Rejected alternatives:**
  - Namespaced-only references — rejected because the namespace is meaningless outside the plugin.
  - Drop cross-references — rejected because it degrades the suite's coherence.
- **Linked technical notes:** —
- **Driven by findings:** F8, F9
- **Dependent decisions:** —
- **Referenced in spec:** Primary Flow, Alternate Flows and States

### D10: Skill-directory path variables

- **Question:** How do skills that invoke their bundled scripts or read their bundled files reference them over the channel?
- **Decision:** Every `${CLAUDE_SKILL_DIR}` path reference in shipped skill content is rewritten to a skill-root-relative path: `${CLAUDE_SKILL_DIR}/scripts/foo.sh` becomes `scripts/foo.sh`, and `${CLAUDE_SKILL_DIR}/references/x.md` becomes `references/x.md`. This is the eighth rewrite class, part of the compatibility rewrite set.
- **Rationale:** The variable is a Claude Code built-in. The agent-skills specification defines no skill-path variable and prescribes relative paths from the skill root for referencing bundled files. Leaving the references would break script steps on the agents that do not define the variable.
- **Evidence:** Operator decision, 2026-10-16 ("this is an eighth rewrite class and we should do it as part of this work"). Agent-skills specification, file-references section (fetched 2026-10-16). Repo sweep: 57 reference sites across the skill folders (28 in `SKILL.md` files across 15 skills; 30 script invocations, 36 file reads, 9 carrying both; none inside command-substitution probes).
- **Rejected alternatives:**
  - Leave the references and accept degraded script steps on agents that do not define the variable — rejected by the operator.
  - Rewrite to per-agent variables — rejected because the agent-skills specification defines no standard skill-path variable, so there is nothing portable to target.
  - Inline the script contents into the skill instructions — rejected because it discards the bundled script files the CLI installs.
- **Linked technical notes:** T6
- **Driven by findings:** implementation-stage OQ-1 (structural-analyst finding F-S1)
- **Dependent decisions:** D3 (the rewrite rides the same codemod), D7 (the packaging guard asserts it)
- **Referenced in spec:** Primary Flow, Out of Scope
