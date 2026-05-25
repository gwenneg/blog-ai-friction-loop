---
name: setup-friction-capture
description: Install the friction capture toolkit — session hooks that record AI friction events and remind developers to improve context docs
allowedTools:
  - Bash(bash *)
  - Bash(cat *)
  - Bash(chmod *)
  - Bash(curl *)
  - Bash(echo *)
  - Bash(jq *)
  - Bash(mkdir *)
  - Edit
  - Read
  - Write
---

# Instructions

## Phase 1: Install or update the toolkit files

Output the following text verbatim to the user before taking any other action in this phase:

> **Friction capture** is a lightweight feedback loop that records the moments when an AI agent struggled — questions it had to ask, conventions it had to guess at, extra files it had to read, or mistakes the user had to correct. Those moments are called *friction events*. At the end of each session, a hook captures them into `.claude/friction/`. Once enough sessions have accumulated (default: 3), Claude Code shows a non-blocking reminder at startup so developers know to run `/update-context-docs`. That command processes the logs and improves the repo's context docs so the same friction doesn't recur.
>
> This phase installs the toolkit: a session-start reminder script (`friction-reminder.sh`), a session-end capture script (`friction-capture.sh`), a self-updating installer (`install-friction-capture.sh`), and the `/update-context-docs` and `/disable-friction-capture` skill files.

If `.claude/scripts/install-friction-capture.sh` already exists, run it directly:

```bash
bash .claude/scripts/install-friction-capture.sh
```

Otherwise, bootstrap by downloading the update script first, then run it:

```bash
TAG=$(curl -fsSL https://api.github.com/repos/gwenneg/blog-ai-friction-loop/releases/latest | jq -r '.tag_name')
if [[ -z "$TAG" || "$TAG" == "null" ]]; then
  echo "Error: could not fetch latest release tag." >&2
  exit 1
fi

mkdir -p .claude/scripts
curl -fsSL "https://raw.githubusercontent.com/gwenneg/blog-ai-friction-loop/${TAG}/skills/setup-friction-capture/scripts/install-friction-capture.sh" \
  -o .claude/scripts/install-friction-capture.sh
chmod +x .claude/scripts/install-friction-capture.sh

bash .claude/scripts/install-friction-capture.sh
```

In both cases: exit codes 0 and 2 mean success — continue to Phase 2. Any other non-zero exit means failure — stop and report the error.

## Phase 2: Configure the hooks

Output the following text verbatim to the user before taking any other action in this phase:

> Two hooks wire the toolkit into Claude Code automatically. A `SessionStart` hook fires at the start of every new conversation and shows a friendly, eye-catching reminder whenever unprocessed friction has accumulated past the threshold (default: 3 sessions) — nothing is blocked, the message is purely informational. A `SessionEnd` hook fires when a conversation ends (including when the user runs `/clear`) and runs `friction-capture.sh` in the background to capture friction events into `.claude/friction/`, one directory per session.
>
> To change the reminder threshold, set `FRICTION_SESSION_THRESHOLD` in `.claude/settings.json` under the `env` key — for example `"FRICTION_SESSION_THRESHOLD": "5"` to wait for 5 sessions before reminding. Each developer can also override it locally in `.claude/settings.local.json`.

Read `.claude/settings.json` if it exists.

Check whether a SessionStart hook already calls `friction-reminder.sh`. If not, add it:
```json
{
  "matcher": "",
  "hooks": [
    {
      "type": "command",
      "command": "bash .claude/scripts/friction-reminder.sh",
      "timeout": 2000
    }
  ]
}
```

Check whether a SessionEnd hook already calls `friction-capture.sh`. If not, add it:
```json
{
  "matcher": "",
  "hooks": [
    {
      "type": "command",
      "command": "bash .claude/scripts/friction-capture.sh",
      "timeout": 5000
    }
  ]
}
```

Use `jq` to merge both entries into the existing `hooks.SessionStart` and `hooks.SessionEnd` arrays, preserving all other content. If `.claude/settings.json` does not exist, create it with just the hooks block.

## Phase 3: Update .gitignore

Output the following text verbatim to the user before taking any other action in this phase:

> The `.claude/` directory mixes things that should be committed (hooks, scripts, skills, settings) with things that should never be (friction logs, local settings, worktrees, lock files). Rather than listing every sensitive path individually, this phase uses an allowlist pattern: ignore everything in `.claude/` by default, then explicitly re-allow only the paths that belong in the repo.

Fetch the `.gitignore.example` file from this repository:

```bash
TAG=$(cat .claude/.friction-capture-version)
curl -fsSL "https://raw.githubusercontent.com/gwenneg/blog-ai-friction-loop/${TAG}/.gitignore.example"
```

For each line in the fetched content, check whether it already exists in the project's `.gitignore`. Add any missing lines. Never duplicate existing entries. If `.gitignore` does not exist, create it.

## Phase 4: Commit and open a PR

Stage these files:
- `.claude/scripts/friction-capture.sh`
- `.claude/scripts/friction-reminder.sh`
- `.claude/scripts/install-friction-capture.sh`
- `.claude/skills/disable-friction-capture/SKILL.md`
- `.claude/skills/update-context-docs/SKILL.md`
- `.claude/.friction-capture-version`
- `.claude/settings.json`
- `.gitignore`

Create a branch named `chore/setup-friction-capture` (add `-2`, `-3`, etc. if it already exists).

Commit with message: `chore: set up friction capture ($(cat .claude/.friction-capture-version))`

Push the branch and open a PR with a body that describes what was added and includes this note for reviewers:

  > **For each team member:** friction capture is enabled by default after this PR is merged. To opt out, set `FRICTION_CAPTURE=0` in your `.claude/settings.local.json`. That file is not committed and stays local.

Include the standard `Generated with Claude Code` footer.
