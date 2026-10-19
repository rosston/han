---
paths:
  - "**/skills/**/*.md"
  - "**/skills/**/scripts/**"
---

# Script Execution Instructions in SKILL.md

When a skill needs to run shell scripts during its steps, the SKILL.md body must describe the invocation as numbered
prose steps — not fenced code blocks.

## The Correct Pattern

Use numbered prose steps with explicit action verbs, and name each script by its path relative to the skill root:

```markdown
1. Generate a unique temp file path by running `scripts/create-review-tempfile.sh`. Capture the
   output — it is the temp file path.
2. Write the content to the temp file path using the Write tool. Do not use Bash for this step.
3. Post the review by running
   `scripts/post-pr-review.sh {owner/repo} {pr_number} {head_sha} {event_type} {temp_file_path}`.
```

Each step has three elements:

1. **Action verb** — "Generate", "Write", "Post", "Run" — tells the agent what to do
2. **Skill-root-relative path** — `scripts/foo.sh` names the script bundled in this skill's own folder
3. **Explanation of inputs/outputs** — what to capture, where values come from

## Why Fenced Code Blocks Are Wrong

Fenced code blocks with comments as pseudocode are ambiguous:

````markdown
<!-- BAD — do not do this -->

    ```
    # generate a unique temp file path
    scripts/create-review-tempfile.sh

    # write content to the temp file
    # use the Write tool, not Bash

    # post the review
    scripts/post-pr-review.sh {args}
    ```
````

Problems:

- **Ambiguous intent** — Claude may treat a fenced code block as display code (show to user) rather than executable
  instructions (run these commands). Prose with action verbs is unambiguous.
- **No resolution cue** — `scripts/...` resolves against the skill's installed folder, not the project the agent runs
  from, and a fenced block states no instruction at all; prose inside a step tells the agent which bundled script to
  run and what to do with its output.
- **No action verbs** — Comments like `# generate a temp file` describe what should happen but don't instruct the
  agent to do it. Prose like "Generate a temp file by running..." is a direct instruction.

## How Skill-Root-Relative Paths Resolve

The agent-skills specification pins file references to paths relative to the skill root — "Run the extraction script:
scripts/extract.py" is its own example. A skill installs as a folder, and its bundled `scripts/` and `references/`
directories sit inside that folder; the agent anchors skill-root-relative paths against the installed skill
directory. How each agent learns that directory is agent-side behavior.

Claude Code additionally substitutes its own skill-directory variable into shell command text before the command
runs. No other supported agent defines such a variable, so Han ships the portable skill-root-relative form everywhere:
the same instructions work over the plugin channel and the skills channel alike. The release end-to-end pass observes
a script-invoking skill on a non-Claude agent to confirm the step succeeds.

## Why Scripts Should Not Be in `allowed-tools`

`Bash()` patterns in the `allowed-tools` frontmatter are **prefix-based matches**. The pattern
`Bash(scripts/create-review-tempfile.sh)` matches commands that start with `scripts/create-review-tempfile.sh` — but at
runtime the command the agent actually executes may carry the skill's absolute install path, not the relative form
written in the SKILL.md, and then the prefix will not match.

Since script commands can't be reliably auto-approved, omit them from `allowed-tools`. Scripts typically run once per
skill invocation, so a single user approval is acceptable.

## Each Skill Gets Its Own Scripts

Skills must be self-contained. If two skills use the same script, each skill gets its own copy in its own `scripts/`
directory. Do not reference scripts from another skill's directory — this creates a hidden dependency that breaks if
the other skill is modified or removed.

## Summary

| Rule            | Details                                                                         |
| --------------- | ------------------------------------------------------------------------------- |
| Format          | Numbered prose steps with action verbs                                          |
| Paths           | Skill-root-relative: `scripts/foo.sh`, `references/x.md`                        |
| Code blocks     | Never use fenced code blocks for script execution steps                         |
| `allowed-tools` | Do not list scripts — the executed command may not prefix-match the written one |
| Self-contained  | Each skill owns its own scripts; no cross-skill references                      |
