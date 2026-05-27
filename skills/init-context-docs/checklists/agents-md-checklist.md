# AGENTS.md Quality Checklist

Used by both generation agents (to know what good looks like before writing) and verification agents (to confirm or correct the output).

## Hard Constraints

- [ ] Present at repo root as `AGENTS.md`
- [ ] Under 200 lines — if over, move domain-specific content into `docs/*-guidelines.md` files; the 200-line limit is a ceiling, not a target
- [ ] No secrets, API keys, passwords, or tokens
- [ ] Every section is strictly necessary — context files with unnecessary content reduce agent task success rates; apply the test "Would removing this cause an agent to make a mistake?" and cut anything that fails

## Docs Index

- [ ] Contains an index of all `docs/*-guidelines.md` files with a one-line description of each
- [ ] Every link in the index points to a file that actually exists
- [ ] No guideline file is missing from the index

## Content Quality

- [ ] Agent-agnostic — no Claude Code-specific commands or behavior (those go in CLAUDE.md)
- [ ] Most important conventions appear first; docs index appears last — agents pay strongest attention to the beginning and end of documents; content in the middle receives the least attention (lost-in-the-middle effect)
- [ ] Covers cross-cutting conventions that span multiple domains and are not already in the guideline files or README.md (naming, code style, architecture, PR expectations)
- [ ] Architectural context is repo-specific, and captures decisions and constraints (the *why*), not structural maps or file listings
- [ ] Common pitfalls reference actual patterns or incidents from this codebase, not generic warnings
- [ ] Includes how to run the test suite so agents can verify their own work

## No Duplication

- [ ] Does not repeat content from README.md
- [ ] Does not repeat domain-specific rules already in `docs/*-guidelines.md` files
- [ ] Does not contain Claude Code-specific content (belongs in CLAUDE.md)

## Verification Commands

```bash
wc -l AGENTS.md                                                        # must be < 200
grep -iE "(api_key|password|secret|token|credential)\s*[:=]\s*(\"[^\"]{4,}\"|'[^']{4,}'|[A-Za-z0-9+/_-]{20,})" AGENTS.md  # must be empty
grep -c "docs.*guidelines" AGENTS.md                                   # must be > 0
find docs -name "*-guidelines.md" | sort                               # compare against index entries
grep -iE "claude code|claude-specific" AGENTS.md                       # should be empty
```
