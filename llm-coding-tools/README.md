# llm-coding-tools

AI-assisted engineering tools and workflows — multi-engineer configuration patterns, scaffolding scripts, and usage guides for GitHub Copilot, Claude Code, and local LLMs.

---

## ai-project-setup

Scaffold a consistent multi-engineer AI configuration in any repo in under a minute.

### Install (macOS, XDG `~/.local/bin/`)

```bash
curl -fsSL https://raw.githubusercontent.com/VirtuallyScott/battle-tested-devops/main/llm-coding-tools/install.sh | bash
# or
wget -qO- https://raw.githubusercontent.com/VirtuallyScott/battle-tested-devops/main/llm-coding-tools/install.sh | bash
```

### Usage

```bash
# Scaffold AI config files in the current repo (interactive)
cd /path/to/your-repo
ai-project-setup init

# Force-overwrite existing files
ai-project-setup init --force

# Upgrade to the latest version
ai-project-setup --upgrade

# Show version
ai-project-setup --version
```

### What gets scaffolded

| File | Purpose |
| --- | --- |
| `CLAUDE.md` | Shared Claude Code session context |
| `.github/copilot-instructions.md` | Shared GitHub Copilot context |
| `.claude/rules/project.md` | Committed project conventions (single source of truth) |
| `.claude/rules/security.md` | Committed security rules |
| `.claude/commands/example.md` | Example shared slash command |
| `.claude/personal/.gitkeep` | Documents the gitignored personal override pattern |
| `.github/PULL_REQUEST_TEMPLATE.md` | Consistent AI-generated PR descriptions |
| `.github/ISSUE_TEMPLATE/bug_report.md` | Bug report template |
| `.github/ISSUE_TEMPLATE/feature_request.md` | Feature request template |

`.gitignore` is updated automatically with `.claude/personal/` and `.claude/settings.local.json`.

`init` is idempotent — existing files are never overwritten unless you pass `--force`.

---

## Files

| File | Description |
| --- | --- |
| [`install.sh`](install.sh) | One-line bootstrap installer |
| [`ai-project-setup.sh`](ai-project-setup.sh) | Main script with embedded templates |
| [`MULTI_ENGINEER_AI_SETUP.md`](MULTI_ENGINEER_AI_SETUP.md) | Full methodology guide |

---

📁 This directory is part of the [Battle-Tested DevOps](../README.md) repository.
