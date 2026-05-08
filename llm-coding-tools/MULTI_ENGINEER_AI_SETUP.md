# Multi-Engineer AI Tool Configuration

How to configure any shared repo so GitHub Copilot and Claude Code work well for a whole team — without engineers stepping on each other's preferences.

> **Everyone uses both Copilot and Claude?** The primary risk is convention drift — defining the same rules in two places that silently diverge. The structure below solves this with a single source of truth in `.claude/rules/`, with both tools drawing from it.

---

## Quick Start

Scaffold the full structure in any repo with a single command:

```bash
# Install once
curl -fsSL https://raw.githubusercontent.com/VirtuallyScott/battle-tested-devops/main/llm-coding-tools/install.sh | bash

# Scaffold a repo
cd /path/to/your-repo
ai-project-setup init

# Keep it current
ai-project-setup --upgrade
```

The installer places `ai-project-setup` at `~/.local/bin/` (XDG-compliant, macOS).
The `init` command is idempotent — it never overwrites files that already exist.

---

## The 3-Tier Config Hierarchy

```text
~/.claude/rules/              ← Tier 1: System-level personal (never touches any repo)
~/.claude/agents/

./CLAUDE.md                   ← Tier 2: Repo-shared (committed, everyone inherits)
./.github/copilot-instructions.md
./.claude/rules/
./.claude/commands/

./.claude/personal/           ← Tier 3: Per-engineer repo overlay (gitignored)
./.claude/settings.local.json ← (gitignored)
./.vscode/                    ← (gitignored)
```

**The rule:** anything contentious or personal stays out of the committed layer.

---

## What to Commit (Shared)

### `CLAUDE.md` (repo root)

Claude Code's shared project context — read automatically at the start of every session.
**Conventions live in `.claude/rules/` — do not repeat them here.** `CLAUDE.md` is for build commands, project structure, and orientation only.

```markdown
# my-project

Brief description of what this repo does.

## Build / Run
- Install deps: `<command>`
- Run locally:  `<command>`
- Run tests:    `<command>`
- Lint:         `<command>`

## Structure
- `src/`   — application source
- `tests/` — test suites
- `docs/`  — documentation

## Rules
- Coding conventions: `.claude/rules/project.md`
- Security rules:     `.claude/rules/security.md`
```

### `.github/copilot-instructions.md`

GitHub Copilot's repo-level brain. **Do not duplicate conventions here** — summarize and point to `.claude/rules/`. This prevents drift when rules change.

```markdown
# Copilot Instructions — my-project

## Project Context
Brief description. Primary language/framework. Key dependencies.

## Conventions
Full rules live in `.claude/rules/project.md`. Key points:
- <convention 1>
- <convention 2>

## Security
Full rules live in `.claude/rules/security.md`. Key points:
- Never suggest hardcoded secrets
- Validate all user input at system boundaries
```

### `.claude/rules/` (committed) — the single source of truth

**This is the canonical location for all shared conventions.** Both `CLAUDE.md` and `copilot-instructions.md` reference these files rather than repeating their content. When a rule changes, it changes in one place.

Claude Code loads these automatically. Copilot does not load them directly — that's why `copilot-instructions.md` carries a summary.

Example `.claude/rules/project.md`:

```markdown
# Project Conventions
- <language/framework-specific rule>
- <naming convention>
- <structure rule>
- <tooling rule>
```

Example `.claude/rules/security.md`:

```markdown
# Security Rules
- Never hardcode secrets — use environment variables or a secrets manager
- Validate all inputs at system boundaries
- Use parameterised queries — never string-concatenate SQL
- Sanitise all output rendered to HTML
```

### `.claude/commands/` (committed)

Shared slash commands available to the whole team in Claude Code.

Example `.claude/commands/run-tests.md`:

```markdown
Run the test suite and report coverage.

$SHELL -c "<your test command here>"
```

### `.github/PULL_REQUEST_TEMPLATE.md`

AI-generated PR descriptions will use this template as their structure.

### `.github/ISSUE_TEMPLATE/`

Bug report and feature request templates keep AI-generated issues consistent.

---

## What to Gitignore (Personal)

Add to `.gitignore`:

```gitignore
# AI tool personal overrides
.claude/personal/
.claude/settings.local.json
```

---

## Personal Override Pattern

Each engineer creates `.claude/personal/` locally. Claude Code loads all `.md` files recursively from `.claude/`, so files in `personal/` are picked up automatically — no extra config needed.

**Engineer who wants verbose explanations:**

```markdown
# .claude/personal/preferences.md
# Personal Preferences
- Step-by-step explanations with rationale
- Show diff before applying changes
- Ask for confirmation before running destructive commands
```

**Engineer who wants minimal output:**

```markdown
# .claude/personal/preferences.md
# Personal Preferences
- Terse responses, no preamble
- Apply changes directly, skip confirmation
```

Neither conflicts with the shared rules. The `personal/` directory has a `.gitkeep` committed so new engineers know the pattern exists.

---

## Divergent Preference Decision Table

| Preference Type | Where It Lives |
|---|---|
| Project conventions (naming, structure, tooling) | `.claude/rules/project.md` (canonical) — summarized in `copilot-instructions.md` |
| Security rules the whole team must follow | `.claude/rules/security.md` (committed) |
| Shared slash commands / workflows | `.claude/commands/` (committed) |
| Personal verbosity, explanation style | `~/.claude/rules/` (system-level, never any repo) |
| Per-repo personal overrides | `.claude/personal/` (gitignored) |
| Allowed tool permissions | `.claude/settings.local.json` (gitignored) |
| Editor settings | `~/.vscode/` or user profile (never repo) |

---

## Full Target Structure

```text
<repo-root>/
├── CLAUDE.md                            # Shared Claude context
├── .github/
│   ├── copilot-instructions.md          # Shared Copilot context
│   ├── PULL_REQUEST_TEMPLATE.md         # AI-generated PRs follow this
│   └── ISSUE_TEMPLATE/
│       ├── bug_report.md
│       └── feature_request.md
└── .claude/
    ├── rules/                           # COMMITTED — shared conventions
    │   ├── project.md
    │   └── security.md
    ├── commands/                        # COMMITTED — shared slash commands
    │   └── example.md
    ├── agents/                          # COMMITTED — shared subagents (optional)
    ├── settings.local.json              # GITIGNORED — personal tool permissions
    └── personal/                        # GITIGNORED — per-engineer overrides
        └── .gitkeep
```

---

## CONTRIBUTING.md Addition

Add this section so new engineers know the setup:

```markdown
## AI Tool Setup

### GitHub Copilot
Repo-level instructions live in `.github/copilot-instructions.md`.
No setup required — Copilot picks these up automatically.

### Claude Code
Shared project context is in `CLAUDE.md` and `.claude/rules/`.

For personal preferences (verbosity, style, etc.):
1. Create `.claude/personal/` locally — it is gitignored
2. Add `.md` files with your preferences
3. Or use `~/.claude/rules/` for preferences that apply across all your repos

Never commit `.claude/settings.local.json` — it contains your personal tool permissions.
```

---

## Files Scaffolded by `ai-project-setup init`

| File | Purpose |
|---|---|
| `CLAUDE.md` | Shared Claude session context |
| `.github/copilot-instructions.md` | Shared Copilot context |
| `.claude/rules/project.md` | Committed project conventions |
| `.claude/rules/security.md` | Committed security rules |
| `.claude/commands/example.md` | Example shared slash command |
| `.claude/personal/.gitkeep` | Documents the personal override pattern |
| `.github/PULL_REQUEST_TEMPLATE.md` | Consistent AI-generated PR descriptions |
| `.github/ISSUE_TEMPLATE/bug_report.md` | Bug report template |
| `.github/ISSUE_TEMPLATE/feature_request.md` | Feature request template |

The script also appends the required entries to `.gitignore`.
