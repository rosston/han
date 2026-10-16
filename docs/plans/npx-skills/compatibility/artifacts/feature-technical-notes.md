# Feature Technical Notes: npx skills compatibility for Han

These notes capture implementation mechanics that are load-bearing for the behavioral specification. Behavioral statements live in [../feature-specification.md](../feature-specification.md). This file exists because the interview and the review round captured five mechanics that change observable behavior and are not discoverable from the Han repo alone; T6 was added during implementation planning (2026-10-16).

## T1: Discovery mechanism

- **Context:** Primary Flow step 1 commits that the listing shows all 45 plugin skills, grouped by plugin package. The commitment is only correct because of how the CLI discovers skills in a multi-package repo.
- **Technical detail:** The CLI reads the repo's root plugin-marketplace manifest (`.claude-plugin/marketplace.json`) and, for each plugin entry, joins the entry's source directory and searches both the entry's declared skill paths and the conventional `skills/` folder inside that source. Discovered names dedupe, so a skill found by both paths lists once. The CLI also reads a root `.claude-plugin/plugin.json` the same way; Han has none at root. Skills list under their plugin entry's name, which produces the grouped listing.
- **Supports decisions:** D1, D6
- **Driven by findings:** —
- **Referenced in spec:** Primary Flow, Coordinations

## T2: Install scope

- **Context:** D3's self-containment commitment rests on what an install actually copies.
- **Technical detail:** Installing a skill copies (or symlinks) exactly one folder — the skill's directory, including everything inside it — into the target agent's skills directory. Nothing outside the folder is installed. After install, the skill's relative links resolve against its new location inside the agent's skills directory, so a link that pointed outside the folder in the repo dangles. Per-skill `references/` and `scripts/` subfolders ride along; package-level references, agents, hooks, and shared scripts do not.
- **Supports decisions:** D3
- **Driven by findings:** —
- **Referenced in spec:** Primary Flow, Edge Cases and Failure Modes

## T3: Internal-skill marker

- **Context:** D4 hides the two maintenance skills from the default listing.
- **Technical detail:** The CLI reads a skill's frontmatter. A skill marked internal under `metadata` is hidden from normal discovery and installs only when the installer opts in via the documented environment variable. Agents that do not implement the marker ignore it, so the repo's own plugin-based dev setup is unaffected.
- **Supports decisions:** D4
- **Driven by findings:** —
- **Referenced in spec:** Primary Flow, Alternate Flows and States

## T4: Manifest entry semantics

- **Context:** D6 adds explicit skill declarations to marketplace entries, and the plugin channel must not change.
- **Technical detail:** In the plugin channel, a marketplace entry accepts the same component fields as the plugin's own manifest, including its skills list. Under the default strict mode, the plugin's own manifest stays the authority and the entry's component fields are appended to it. An entry declaration that restates skills the plugin already ships by convention must therefore be verified — by manifest validation and a local marketplace install — not to double-load the same skills.
- **Supports decisions:** D6
- **Driven by findings:** —
- **Referenced in spec:** Alternate Flows and States, Edge Cases and Failure Modes

## T5: Agent-specific setup probes

- **Context:** D5 commits that configuration resolution behaves the same on every supported agent. The commitment is only correct because the resolution does not depend on a skill-file feature that some agents do not implement.
- **Technical detail:** Command-substitution blocks embedded in a skill's instructions are a feature of one agent's skill format. An agent whose skill format does not execute them never runs the resolution those blocks carry, so the portable resolution lives in the skill's instructions, which every agent executes. The per-agent matrix of which formats execute such blocks is not enumerated here; the commitment is stated so that the resolution never depends on it.
- **Supports decisions:** D5
- **Driven by findings:** F3
- **Referenced in spec:** Primary Flow, Edge Cases and Failure Modes

## T6: Skill-root-relative references

- **Context:** D10 rewrites every `${CLAUDE_SKILL_DIR}` reference to a skill-root-relative path. The commitment is only correct because of what the agent-skills specification prescribes for referencing bundled files.
- **Technical detail:** The agent-skills specification's file-references section prescribes relative paths from the skill root ("See [the reference guide](references/REFERENCE.md)"; "Run the extraction script: scripts/extract.py"), and its frontmatter schema defines no skill-path variable. `${CLAUDE_SKILL_DIR}` is a Claude Code built-in, not part of the standard. None of the affected references sit inside command-substitution probes, so T5's caveat does not apply to them. Whether every target agent's shell resolves a skill-root-relative script path is agent-side; the release end-to-end pass observes a script-invoking skill on a non-Claude agent.
- **Supports decisions:** D10
- **Driven by findings:** implementation-stage OQ-1 (F-S1)
- **Referenced in spec:** Primary Flow, Out of Scope
