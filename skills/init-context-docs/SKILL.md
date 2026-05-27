---
name: init-context-docs
description: Assess a repository's readiness for AI-assisted development and bootstrap its layered documentation structure (guidelines, AGENTS.md, CLAUDE.md, README.md)
allowedTools:
  - Bash(cat *)
  - Bash(find *)
  - Bash(grep *)
  - Bash(ls *)
  - Bash(mkdir *)
  - Edit
  - Glob
  - Read
  - Write
---

# Instructions

## Phase 1: Introduction

Output the following text verbatim to the user before taking any other action:

> This skill helps you build a layered documentation system for AI-assisted development. Each file has a distinct role:
>
> - **`docs/*-guidelines.md`** — Detailed, domain-specific playbooks (security, testing, database, etc.) with concrete rules agents follow, including how to verify compliance. Loaded on demand via the index in AGENTS.md or via Claude rules.
> - **`.claude/rules/*.md`** — Optional path-scoped loaders: each file imports a guideline and declares which file patterns trigger it, so the guideline only loads when relevant.
> - **`AGENTS.md`** — The open-standard onboarding doc for any AI agent (Claude, Cursor, GitHub Copilot, OpenAI Codex, Gemini CLI, Windsurf, etc.): cross-cutting conventions + an index pointing to the guideline files.
> - **`CLAUDE.md`** — A thin, Claude Code-specific layer that imports AGENTS.md and adds Claude-only behavior (build commands, etc.). Loaded unconditionally at the start of every session.
> - **`README.md` or `README.adoc`** — The front door: high-level project context for humans and agents alike.
>
> We'll check what's already in place, then walk through each file one phase at a time.
>
> **Note:** This is a demo skill. In a real-world project you might also want `CONTRIBUTING.md` (contribution conventions for both humans and agents) and `ARCHITECTURE.md` (high-level system design and key architectural decisions). This skill won't create those files.
>
> *This skill's design is grounded in first-party guidance from Anthropic and academic research (peer-reviewed papers marked ✅):*
> - [Effective Context Engineering for AI Agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) — Anthropic
> - [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices) — Anthropic
> - [AGENTS.md open standard](https://agents.md/) — Linux Foundation
> - [Evaluating AGENTS.md: Are Repository-Level Context Files Helpful for Coding Agents?](https://arxiv.org/pdf/2602.11988) — Gloaguen et al. (ETH Zurich), arXiv preprint, 2026
> - ✅ [Lost in the Middle](https://arxiv.org/pdf/2307.03172) — Liu et al. (Stanford), TACL 2024
> - ✅ [Context Length Alone Hurts LLM Performance Despite Perfect Retrieval](https://arxiv.org/pdf/2510.05381) — Du et al., EMNLP Findings 2025
> - ✅ [On the Emergence of Position Bias in Transformers](https://arxiv.org/pdf/2502.01951) — Wu et al. (MIT), ICML 2025
> - [On the Impact of AGENTS.md Files on the Efficiency of AI Coding Agents](https://arxiv.org/pdf/2601.20404) — Lulla et al. (Heidelberg, Bamberg, Singapore Management University), arXiv preprint, 2026
>
> **Key finding:** Two complementary studies point to the same conclusion: well-formed, minimal context files are associated with ~29% lower agent runtime and ~17% fewer output tokens (Lulla et al.), while files with unnecessary content actively reduce task success rates compared to no context at all (Gloaguen et al.). Every line added to these files should pass a strict necessity test: *"Would removing this cause an agent to make a mistake?"* If not, leave it out. The goal of this skill is the smallest set of high-signal content — not the most comprehensive documentation.

Use the AskUserQuestion tool to ask the user if they are ready to proceed.

## Phase 2: Assess (before)

Check whether each requirement is met, then present the results — do not modify any files:

```
| Requirement                                                            | Status |
|------------------------------------------------------------------------|--------|
| At least one `docs/*-guidelines.md` with domain-specific rules         |   ?    |
| `AGENTS.md` with cross-cutting conventions and a docs index            |   ?    |
| `CLAUDE.md` with `@AGENTS.md` import                                   |   ?    |
| `README.md` or `README.adoc` with project overview and getting-started |   ?    |
```

Replace each `?` with ✅ if met, ❌ if not. Then proceed to phase 3.

## Phase 3: Generate or update domain-specific guideline files

Output the following text verbatim to the user before taking any other action in this phase:

> Guideline files (`docs/*-guidelines.md`) are the deepest layer of the documentation system. They contain detailed, domain-specific rules — concrete conventions from your repo, not generic knowledge. Each guideline also tells agents how to verify their work: what commands to run, what output to check, what a passing state looks like.
>
> `AGENTS.md` will index these files. Optionally, each guideline can be paired with a `.claude/rules/<domain>.md` file that forces it into context whenever Claude works with matching files.
>
> **Each guideline file is capped at 200 lines** — context length alone degrades LLM performance regardless of content quality, so the most critical rules go first and verification commands go last.

Use the AskUserQuestion tool to ask the user if they want to generate or update guideline files. If they decline, skip to the next phase.

If they accept, follow this process:

### 3.1. Identify relevant domains

First, check if `AGENTS.md` exists and contains a docs index section. If it does, extract the domains already listed there — these were identified in a previous run and should be included in the suggested list.

Then, start from this curated list of domains:

| Domain | Includes |
|--------|----------|
| api-contracts | API design, REST conventions, versioning |
| async-and-messaging | async processing, message queues, event-driven architecture and background job conventions |
| code-organization | project structure conventions, module boundaries and import patterns |
| configuration | environment variables, feature flags and secrets handling |
| data-validation | serialization, deserialization and schema enforcement patterns |
| database | schema design, query patterns and migrations |
| dependency-management | version management, upgrade policies and supply chain conventions |
| deployment | deployment pipelines, infra-as-code conventions, environment management and release process |
| error-handling | error handling patterns and propagation |
| integration | integration patterns, external services and webhooks |
| logging-and-observability | logging standards, metrics, tracing and diagnostic conventions |
| performance | concurrency, thread safety, resource contention |
| security | security patterns, authentication and authorization |
| testing | test patterns and coverage |

Merge the curated list with any previously identified domains from AGENTS.md (including custom domains the user may have added in a prior run).

Use an Explore agent with the Sonnet model to scan the repository and determine:
1. Which domains from the merged list are relevant — a domain is relevant if the repo contains code, configuration, or patterns that fall within that domain (e.g., skip `database` if there is no database usage, skip `api-contracts` if there are no REST APIs)
2. Any additional domains not on the curated list that would benefit from a dedicated guideline — look for prominent frameworks, toolchains, workflows, or cross-cutting patterns in the repo that don't fit any curated category (e.g., `graphql`, `machine-learning`, `mobile-ios`, `data-pipeline`)

Present the combined list to the user. Use AskUserQuestion to confirm the final list, allowing the user to add, remove, or rename any entry.

### 3.2. Explore and generate guidance

Tell the user that background agents are now running for each confirmed domain and that this may take a few minutes depending on the size of the codebase.

For each confirmed domain, launch an Explore agent in the background using the Opus model. Each agent must:

1. Read `checklists/guideline-checklist.md` to understand the quality criteria the guideline must meet
2. Thoroughly explore the repository from its domain perspective — read source code, configuration files, existing documentation, test patterns, and any other relevant files
3. Identify the conventions, patterns, libraries, frameworks, and practices used in the repo for that domain
4. If `docs/<domain>-guidelines.md` already exists, read it first and incorporate its content — update with new findings while preserving still-accurate content
5. Return the complete guideline content as its result — do NOT write any files

The agent decides the structure of the guideline content based on what it finds. The checklist defines all quality criteria.

Once all exploration agents have completed, ensure the `docs/` directory exists and write each guideline to `docs/<domain>-guidelines.md`. Then proceed to verification.

### 3.3. Verify guideline accuracy

Tell the user that verification agents are now running for each guideline. This may take a moment.

For each domain, launch a verification agent in the background (subagent_type: Explore, Sonnet model). Each agent must:

1. Read `checklists/guideline-checklist.md` — this is the single source of truth for what the guideline must satisfy
2. Read `docs/<domain>-guidelines.md` for its assigned domain and all other `docs/*-guidelines.md` files
3. Validate the guideline against every item in the checklist — use Grep, Glob, and WebSearch as needed
4. Return the corrected version of the guideline as its result — do NOT write any files, do NOT add new domain content; only correct inaccuracies, reconcile contradictions, and add a Verification section if one is missing

Once all verification agents have completed, overwrite each `docs/<domain>-guidelines.md` with the corrected content, then tell the user: *Review the changes in `docs/` in your editor or from the PR once it's created.*

### 3.4. Scope guidelines with Claude rules (optional)

Output the following text verbatim to the user before taking any other action in this phase:

> By default, Claude decides whether to load a guideline based on what it judges relevant to the current task — and it may skip one that would have been useful. Claude rules override that judgment: they force a guideline into context whenever Claude works with matching files.
>
> **Use rules sparingly.** Every rule that fires consumes context window tokens unconditionally — the same drawback as an oversized CLAUDE.md, but scoped to matching files. A rule with an overly broad glob pattern (e.g., `**/*`) effectively makes that guideline always-loaded, defeating the purpose of on-demand loading. Prefer narrow patterns that match only the files where the guideline is genuinely needed.
>
> **Alternative:** placing an `AGENTS.md` in a subdirectory that references the guideline works across all agent tools without YAML frontmatter — but loading isn't guaranteed. Use rules when you need a hard guarantee; use subdirectory `AGENTS.md` when cross-tool compatibility matters more.

Use the AskUserQuestion tool to ask the user if they want to configure Claude rules for the generated guidelines. If they decline, skip to the next phase.

If they accept, present ALL guidelines at once in a single table with suggested glob patterns, so the user can review and adjust everything together rather than one by one:

```
| Guideline              | Suggested pattern(s)         | Include? |
|------------------------|------------------------------|----------|
| testing                | **/test/**, **/*Test*        | ?        |
| security               | src/main/**                  | ?        |
| database               | **/migration/**, **/*.sql    | ?        |
```

Allow the user to adjust patterns or exclude any guideline from the table. Use AskUserQuestion to confirm the final set of patterns before proceeding.

Once all patterns are confirmed, create `.claude/rules/` if it does not exist. For each guideline with confirmed patterns, write a `.claude/rules/<domain>.md` file with this structure:

```markdown
---
paths:
  - "<glob-pattern>"
---

@docs/<domain>-guidelines.md
```

If a `.claude/rules/<domain>.md` file already exists, update its `paths` frontmatter and preserve the import line.

After writing all rules files, check whether `.claude/rules/` is gitignored by running:

```bash
git check-ignore -v .claude/rules/
```

If the output is non-empty (meaning the directory is gitignored), report this to the user — explain that the rules files will be excluded from commits and therefore won't take effect for other developers or in CI. Use AskUserQuestion to ask whether to add a `.gitignore` exception. If the user agrees, append `!.claude/rules/` to the relevant `.gitignore` file identified in the `git check-ignore` output.

## Phase 4: Generate or update AGENTS.md

Output the following text verbatim to the user before taking any other action in this phase:

> `AGENTS.md` is now an open standard stewarded by the Linux Foundation, adopted by Claude, Cursor, GitHub Copilot, OpenAI Codex, Gemini CLI, Windsurf, and 60,000+ open-source projects. It is the agent-agnostic onboarding doc for any AI tool — not a Claude-specific file.
>
> It sits between the high-level `README` and the deep domain playbooks in `docs/`: it captures cross-cutting conventions (naming, code style, architecture) and includes an index pointing to the detailed guideline files. `CLAUDE.md` then imports it so Claude gets everything in one shot.

Use the AskUserQuestion tool to ask the user if they want to generate or update AGENTS.md. If they decline, skip to the next phase.

If they accept, follow this process:

### 4.1. Docs index

Detect all existing `docs/*-guidelines.md` files. Present the list to the user and use AskUserQuestion to ask which ones to include in the AGENTS.md docs index. Allow the user to add, remove, or reorder entries before confirming.

### 4.2. AI guidance and repo conventions

Tell the user that a background agent is now exploring the repository to generate AGENTS.md content. This may take a few minutes.

Launch an Explore agent in the background using the Opus model. The agent must:

1. Read `checklists/agents-md-checklist.md` to understand the quality criteria AGENTS.md must meet
2. Thoroughly explore the repository — read source code, configuration files, build scripts, CI/CD pipelines, existing documentation (including README.md or README.adoc if present), and any other relevant files
3. Read all existing `docs/*-guidelines.md` files to understand what's already covered in detail
4. If AGENTS.md already exists, read it first and incorporate its content — update with new findings while preserving still-accurate content
5. Return the complete AGENTS.md content as its result — do NOT write any files

The checklist defines all quality criteria. The docs index must include only the guideline files the user confirmed in phase 4.1 — do not index guidelines the user excluded.

Once the agent has completed, tell the user that a verification agent is now running to validate the proposed AGENTS.md content. This may take a moment.

Launch a verification agent in the background (subagent_type: Explore, Sonnet model). Provide the generated content in the agent's prompt. The agent must:

1. Read `checklists/agents-md-checklist.md` — this is the single source of truth for what AGENTS.md must satisfy
2. Read `README.md` or `README.adoc` and all `docs/*-guidelines.md` files from the repository
3. Validate the provided content against every item in the checklist — use Grep and Glob as needed
4. Return the corrected version of the content as its result — do NOT write any files; only correct inaccuracies and reconcile contradictions

Once the verification agent has completed, write the corrected content to `AGENTS.md`. Tell the user: *Review `AGENTS.md` in your editor or from the PR once it's created.*

## Phase 5: Generate or update CLAUDE.md

Output the following text verbatim to the user before taking any other action in this phase:

> `CLAUDE.md` is the Claude Code-specific layer on top of `AGENTS.md`. It uses `@AGENTS.md` to pull in all agent guidance automatically, then adds anything that only applies to Claude Code.
>
> It is loaded unconditionally at the start of every session, consuming context window tokens regardless of the task. A bloated `CLAUDE.md` causes Claude to ignore your actual instructions. Keep it ruthlessly short — for every line, ask: *"Would removing this cause Claude to make mistakes?"* If not, cut it.

Use the AskUserQuestion tool to ask the user if they want to generate or update CLAUDE.md. If they decline, skip to the next phase.

If they accept, follow this process:

If CLAUDE.md already exists, read it and check whether it contains `@AGENTS.md`. If not, tell the user this import is needed for Claude Code to load the agent guidance, and offer to add it.

Tell the user a background agent is now exploring the repository to propose CLAUDE.md content. This may take a minute.

Launch an Explore agent in the background using the Opus model. The agent must:

1. Read `checklists/claude-md-checklist.md` to understand the quality criteria CLAUDE.md must meet
2. Read AGENTS.md and all `docs/*-guidelines.md` files to understand what is already covered
3. If CLAUDE.md already exists, read it first and incorporate its content — update with new findings while preserving still-accurate content
4. Explore the repository for build scripts, CI/CD pipelines, pre-commit hooks, test commands, and any other configuration exclusive to Claude Code
5. Return the complete CLAUDE.md content as its result — do NOT write any files

The checklist defines all quality criteria.

Once the agent has completed, tell the user that a verification agent is now running to validate the proposed CLAUDE.md content. This may take a moment.

Launch a verification agent in the background (subagent_type: Explore, Sonnet model). Provide the generated content in the agent's prompt. The agent must:

1. Read `checklists/claude-md-checklist.md` — this is the single source of truth for what CLAUDE.md must satisfy
2. Read `AGENTS.md` and all `docs/*-guidelines.md` files from the repository
3. Validate the provided content against every item in the checklist — use Grep and Glob as needed
4. Return the corrected version of the content as its result — do NOT write any files; only correct inaccuracies and reconcile contradictions

Once the verification agent has completed, write the corrected content to `CLAUDE.md`. Tell the user: *Review `CLAUDE.md` in your editor or from the PR once it's created.*

## Phase 6: Generate or update README

Output the following text verbatim to the user before taking any other action in this phase:

> `README.md` is the front door of the repository — high-level project context for both humans and AI agents. A well-structured README can reduce the tool calls agents need during onboarding: when agents can answer "how does this project work?" from the README alone, they have less reason to explore the codebase.
>
> Front-load the most critical information — agents pay strongest attention to the beginning and end of documents; content in the middle receives the least attention (lost-in-the-middle effect).

Use the AskUserQuestion tool to ask the user if they want to generate or update the README. If they decline, skip to the next phase.

If they accept, follow this process:

Check whether `README.md` or `README.adoc` exists at the repo root:
- If `README.adoc` exists and `README.md` does not: use AsciiDoc format, target `README.adoc`
- If `README.md` exists (regardless of whether `README.adoc` also exists): use Markdown format, target `README.md`
- If neither exists: default to Markdown format, target `README.md`

If the target file already exists, read it and present a brief assessment of what's missing or could be improved.

Tell the user that a background agent is now exploring the repository to propose README content. This may take a minute.

Launch an Explore agent in the background using the Opus model. The agent must:

1. Read `checklists/readme-checklist.md` to understand the quality criteria the README must meet
2. Thoroughly explore the repository — read source code, configuration files, build scripts, existing documentation, and any other relevant files
3. Read AGENTS.md and all `docs/*-guidelines.md` files to understand what's already documented elsewhere and avoid duplicating it
4. If the target file already exists, read it first and incorporate its content — update with new findings while preserving still-accurate content
5. Return the complete README content as its result in the appropriate format — do NOT write any files

The checklist defines all quality criteria.

Once the agent has completed, tell the user that a verification agent is now running to validate the proposed README content. This may take a moment.

Launch a verification agent in the background (subagent_type: Explore, Sonnet model). Provide the generated content in the agent's prompt. The agent must:

1. Read `checklists/readme-checklist.md` — this is the single source of truth for what the README must satisfy
2. Read `AGENTS.md` and all `docs/*-guidelines.md` files from the repository
3. Validate the provided content against every item in the checklist — use Grep and Glob as needed
4. Return the corrected version of the content as its result in the appropriate format — do NOT write any files; only correct inaccuracies and reconcile contradictions

Once the verification agent has completed, write the corrected content to the target file. Tell the user: *Review the README in your editor or from the PR once it's created.*

## Phase 7: Assess (after)

Re-check all requirements from phase 2 against the actual file system. Present the before/after comparison — replace each `?` with the ✅/❌ recorded in phase 2 (Before) and the state you just verified (After):

```
| Requirement                                                            | Before | After |
|------------------------------------------------------------------------|--------|-------|
| At least one `docs/*-guidelines.md` with domain-specific rules         |   ?    |   ?   |
| `AGENTS.md` with cross-cutting conventions and a docs index            |   ?    |   ?   |
| `CLAUDE.md` with `@AGENTS.md` import                                   |   ?    |   ?   |
| `README.md` or `README.adoc` with project overview and getting-started |   ?    |   ?   |
```

Then run the automated structural checks against the repo root:

```bash
bash <skill-base-dir>/scripts/automated-checks.sh <repo-root>
```

`<skill-base-dir>` is available in the system-reminder as "Base directory for this skill". `<repo-root>` is the root directory of the repository being assessed (the current working directory if the skill was invoked from the repo root).

Fix any errors you can — only touch files created or modified during this session. For errors in pre-existing files you did not modify, report them as known issues and let the user decide.

Re-run the checks after any fixes. Report what passed, what was fixed, and any remaining issues. Then use AskUserQuestion to ask the user whether to proceed to phase 8.

## Phase 8: Create a pull request (optional)

Use the AskUserQuestion tool to ask the user if they want to create a pull request with all the changes made during this session. If they decline, stop here.

If they want a PR:

1. Check if a branch named `init-context-docs` already exists locally or remotely. If not, create it. If it does, try `init-context-docs-2`, then `init-context-docs-3`, and so on until a free name is found. Use that branch name for the rest of this phase.
2. Stage all changed and new files
3. Commit with a descriptive message summarizing what was created or updated
4. Push the branch and create a pull request using `gh pr create`
5. The PR description must start with: `This PR was generated by the /init-context-docs Claude skill from https://github.com/gwenneg/blog-ai-friction-loop.` and end with: `🤖 Generated with [Claude Code](https://claude.ai/claude-code)`
6. Display the PR link in the chat
