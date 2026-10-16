# Feature Specification: npx skills compatibility for Han

Han's skills install and run through the `npx skills` CLI — the channel mattpocock/skills uses — on every agent that CLI supports, without installing Han as a plugin. The plugin channel keeps shipping the full suite: the same skills, the specialist-agent roster (the expert reviewers a skill can dispatch), and the shared scripts.

## Outcome

A developer on any agent the `npx skills` CLI supports can run `npx skills add testdouble/han`, see Han's skills listed, install the ones they want or all of them, and run them. The channel carries skills only: no specialist agents and no shared scripts. Every rule a skill follows travels with the skill, and personal-configuration resolution behaves the same as a plugin install. Where a skill would normally dispatch a specialist agent, it performs the step itself and says so — the trade-off is named, not hidden. The listing shows the 45 public skills; two repo-maintenance skills install only on explicit opt-in. The plugin channel is unchanged.

## Actors and Triggers

- **Actors** — the developer installing and running Han skills; the `npx skills` CLI, which discovers and installs skills; the target coding agent, which runs the installed skills; Han maintainers, who keep the compatibility contract guarded.
- **Triggers** — a developer runs `npx skills add testdouble/han`, with `--list`, `--skill`, `--agent`, or `--global` as needed; a maintainer changes a skill, the marketplace manifest, or a shared rule file.
- **Preconditions** — the target agent is one the CLI supports (the CLI's documentation lists them). A skill that needs an external integration says so when invoked.

## Primary Flow

1. The developer lists Han's skills. `npx skills add testdouble/han --list` shows the 45 public skills, grouped by plugin package. Two repo-maintenance skills install only when the installer explicitly opts into internal skills ([D1](artifacts/decision-log.md#d1-channel-scope), [D4](artifacts/decision-log.md#d4-internal-maintenance-skills), [T1](artifacts/feature-technical-notes.md#t1-discovery-mechanism), [T3](artifacts/feature-technical-notes.md#t3-internal-skill-marker)).
2. The developer installs skills to one or more agents, at project or global scope. Each skill arrives as one self-contained folder in the agent's skills directory: its rule files, bundled scripts, and bundled files all travel inside the folder, referenced by paths relative to the skill root ([T2](artifacts/feature-technical-notes.md#t2-install-scope), [T6](artifacts/feature-technical-notes.md#t6-skill-root-relative-references), [D10](artifacts/decision-log.md#d10-skill-directory-path-variables)).
3. The developer runs a skill. The skill resolves the personal configuration directory — the directory that holds the developer's personal `.han/config.md` — through its own instructions, the same on every supported agent and the same as a plugin install ([D5](artifacts/decision-log.md#d5-portable-configuration-resolution), [T5](artifacts/feature-technical-notes.md#t5-agent-specific-setup-probes)).
4. The skill reads the rule files it follows. They sit inside the skill folder ([D3](artifacts/decision-log.md#d3-self-contained-skills), [T2](artifacts/feature-technical-notes.md#t2-install-scope)).
5. Where a step would dispatch a specialist agent, the skill performs the step itself. At the first substitution it tells the developer, once, what was substituted and that the independent specialist review is replaced by the calling model's own judgment ([D2](artifacts/decision-log.md#d2-standalone-degradation-for-agent-dispatch)).
6. The skill references another Han skill by its plain name. The reference resolves when that skill is installed too ([D9](artifacts/decision-log.md#d9-cross-skill-references)).

## Alternate Flows and States

### Partial install

- **Entry condition:** the developer installs some, not all, of Han's skills.
- **Sequence:** the installed skill runs. A reference to a Han skill that is not installed is named at the point of use. The run continues with the parts that do not need it. If no part of the run can proceed without the missing skill, the run stops and names the skill to install. At the end of a partial run, the skill summarizes what was omitted ([D9](artifacts/decision-log.md#d9-cross-skill-references)).
- **Exit:** the run completes with the omissions summarized, or the developer installs the missing skill and reruns.

### Updating installed skills

- **Entry condition:** Han ships a new version after the developer installed skills.
- **Sequence:** the developer runs the CLI's update command for the installed skills. The installed folders are refreshed from the same source.
- **Exit:** the skills run the new version. The README names the update command.

### Standalone run of an agent-dispatching skill

- **Entry condition:** the skill is installed without the plugin, and a step would dispatch a specialist agent.
- **Sequence:** the calling model performs the step inline. At the first substituted step, the skill tells the developer, once, what was substituted and that the independent specialist review is replaced by the calling model's own judgment.
- **Exit:** the step completes with the substitution disclosed ([D2](artifacts/decision-log.md#d2-standalone-degradation-for-agent-dispatch)).

### Plugin install, unchanged

- **Entry condition:** the developer installs Han from the plugin marketplace instead.
- **Sequence:** everything works as it does today, including the specialist-agent roster and the shared scripts. Both channels read the same skill folders, and the rule copies those folders carry are kept identical to the canonical files, so the plugin channel always runs the same rules ([D3](artifacts/decision-log.md#d3-self-contained-skills), [D6](artifacts/decision-log.md#d6-explicit-manifest-declarations), [T4](artifacts/feature-technical-notes.md#t4-manifest-entry-semantics)).
- **Exit:** the full suite runs.

### Internal maintenance skills

- **Entry condition:** a developer lists Han's skills over the channel.
- **Sequence:** the repo's two maintenance skills do not appear. They install only when the installer explicitly asks for internal skills. Run outside the Han repository, either skill says it maintains Han's own repository and stops ([D4](artifacts/decision-log.md#d4-internal-maintenance-skills), [T3](artifacts/feature-technical-notes.md#t3-internal-skill-marker)).
- **Exit:** the listing shows the 45 public skills.

## Edge Cases and Failure Modes

Runtime failure modes — what the developer experiences:

| Condition | Required Behavior |
| --- | --- |
| A rule file a skill follows is missing or unreadable (a corrupted or partial install) | The skill names the file and stops before acting on it ([D3](artifacts/decision-log.md#d3-self-contained-skills)) |
| A specialist agent is missing (skills-only install) | The step runs inline with the once-per-run substitution note ([D2](artifacts/decision-log.md#d2-standalone-degradation-for-agent-dispatch)) |
| A project configuration file exists but cannot be read | The skill names the file rather than treating it as absent ([D5](artifacts/decision-log.md#d5-portable-configuration-resolution)) |
| The personal configuration directory cannot be resolved | The skill falls back to the agent's default configuration directory and says so ([D5](artifacts/decision-log.md#d5-portable-configuration-resolution)) |
| A referenced Han skill is missing | The skill names it at the point of use, stops with the skill to install when no part can proceed, and summarizes omissions at the end of the run ([D9](artifacts/decision-log.md#d9-cross-skill-references)) |
| Han is installed through both channels on the same agent | The README's guidance applies: pick one channel per agent. Which copy the agent uses is the agent's own precedence ([D8](artifacts/decision-log.md#d8-readme-documents-both-channels)) |

Release-guard failures — maintainer-facing, caught before release:

| Condition | Required Behavior |
| --- | --- |
| The manifest's declared skills drift from the packages on disk | The packaging guard fails before release ([D7](artifacts/decision-log.md#d7-packaging-guard)) |
| A skill links to a file outside its own folder | The packaging guard fails before release ([D3](artifacts/decision-log.md#d3-self-contained-skills), [D7](artifacts/decision-log.md#d7-packaging-guard)) |
| A skill body hardcodes the configuration home | The packaging guard fails before release ([D5](artifacts/decision-log.md#d5-portable-configuration-resolution), [D7](artifacts/decision-log.md#d7-packaging-guard)) |
| The manifest change double-loads skills in the plugin channel | Validation and the packaging guard catch it before release ([D6](artifacts/decision-log.md#d6-explicit-manifest-declarations), [T4](artifacts/feature-technical-notes.md#t4-manifest-entry-semantics)) |

## User Interactions

- **Affordances:** the CLI's own listing, selection, install, and update prompts. Unchanged, third-party.
- **Feedback:** in-skill notes for the inline-agent substitution (once per run), a missing rule file, and configuration fallback. On an agent that does not honor tool-permission declarations, the skill's setup commands ask for approval per call.
- **Error states:** a missing rule file, an unreadable configuration file, or a missing referenced skill is named in the message, never silently skipped.
- **Documentation:** the README shows both install channels side by side and names the CLI's update command. It states what the skills channel does not carry (specialist agents, shared scripts), names the degraded behaviors, shows the opt-in for the two maintenance skills, and advises one channel per agent ([D8](artifacts/decision-log.md#d8-readme-documents-both-channels)).

## Coordinations

| Coordinating System | Direction | Interaction | Ordering / Consistency Requirement |
| --- | --- | --- | --- |
| `npx skills` CLI and Han repo | inbound | The CLI reads the marketplace manifest to list skills, copies skill folders to install, and refreshes installed folders from the same source on update | The manifest's declared skills and each plugin's actual inventory stay identical; the packaging guard enforces it ([D6](artifacts/decision-log.md#d6-explicit-manifest-declarations), [D7](artifacts/decision-log.md#d7-packaging-guard), [T1](artifacts/feature-technical-notes.md#t1-discovery-mechanism)) |
| Han repo and CI | inbound | The packaging guard runs on every change | A failing guard blocks release ([D7](artifacts/decision-log.md#d7-packaging-guard)) |
| Skill folders and canonical rule files | inbound | Each skill folder carries its own copies of the rule files | The copies stay identical to the canonical files; the packaging guard enforces it ([D3](artifacts/decision-log.md#d3-self-contained-skills)) |
| Skills channel and plugin channel | bidirectional | Both channels read the same skill folders | A change to a skill ships to both channels from one source ([D1](artifacts/decision-log.md#d1-channel-scope)) |

## Out of Scope

- Installing specialist agents or shared scripts over the skills channel. The CLI installs skills only.
- Changes to the `npx skills` CLI itself or to mattpocock/skills. The recorded boundary covers Han's repo only.
- Rewriting skill content beyond what compatibility requires: link targets, setup probes, dispatch steps, vendored rules, hardcoded configuration-home paths, missing-reference handling, reference forms (namespaced and slash-command references normalized to plain skill names), and skill-directory path variables (`${CLAUDE_SKILL_DIR}` references rewritten to skill-root-relative paths).
- Getting Han listed in the skills directory site. Tracked as an open item.

## Cut for Scope

This is work the work item excludes, not work deferred for lack of evidence. Nothing here carries a reopening trigger, because the recorded boundary already settled it.

### Shipping specialist agents and shared scripts over the skills channel

- **Why cut:** the CLI's install model copies skill folders only. The operator asked for parity with mattpocock/skills, whose channel is also skills-only. The reinstatement route is the operator saying so, or the CLI growing support for non-skill components.

## Deferred (YAGNI)

This is work no evidence supports yet, not work the work item excludes. Every entry carries the trigger that would justify revisiting it.

### Per-skill compatibility notes in the README

- **Why deferred:** which skills degrade which steps is derivable from the skills themselves, and no user has asked for a matrix.
- **Reopen when:** users report confusion about which behaviors need the plugin.
- **Source:** conversation context.

### Evaluating installed skills over the skills channel

- **Why deferred:** Han evaluates skills in-repo today, and nothing shows the installed copies diverge.
- **Reopen when:** a compatibility bug ships to the skills channel.
- **Source:** conversation context.

## Open Items

None. OI-1 (whether the skills directory site lists Han automatically or needs a submission)
resolved 2026-10-16: the directory lists Han automatically — the pack page lists all 47 skills and
per-skill pages carry the install command (confirmed by the operator and by fetching the site). The
install command resolves the repository directly from its GitHub source and never depended on the
listing.

## Summary

- **Outcome delivered:** Han's skills install and run through `npx skills` on any supported agent, standalone, with the plugin channel unchanged.
- **Primary actors:** developers installing Han skills; the CLI; the target agent; Han maintainers.
- **Decisions settled by evidence:** 5 — see [artifacts/decision-log.md](artifacts/decision-log.md)
- **Decisions settled by user input:** 5 — see [artifacts/decision-log.md](artifacts/decision-log.md)
- **Sub-agents consulted:** two reviewers (fresh-eyes and resilience roles) — see [artifacts/team-findings.md](artifacts/team-findings.md)
- **Key adjustments from review:** the Outcome now names the channel's real deltas; the update path, configuration-resolution detail, hardcoded-path lint, and partial-install end states are committed — see [artifacts/team-findings.md](artifacts/team-findings.md)
- **Remaining open items:** 0 — OI-1 resolved 2026-10-16 (the skills directory lists Han automatically)
- **Technical notes:** 6 — see [artifacts/feature-technical-notes.md](artifacts/feature-technical-notes.md)
