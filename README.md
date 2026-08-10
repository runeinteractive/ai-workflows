# ai-workflows

Reusable AI workflows for a shared daily development loop. One prompt per task, always-on engineering rules, thin adapters for Cursor, Claude Code, and ChatGPT.

## Daily loop

```text
start-branch -> investigate? -> implement -> review -> fix-ci -> commit -> open-pr -> release
```

Also: `unit-test`, `annotate`. Always-on: `rules/engineering.md`.

**Git defaults:** topic branches `feature/*` · `fix/*` · `hotfix/*` · `refactor/*` · `experiment/*`. PR into `main`, or into an active `release/*` train when the project documents one. No `dev` branch. Project CONTRIBUTING / pipeline docs always win.

## Layout

```text
prompts/     # source of truth
rules/       # always-on standards + loop
adapters/    # Cursor / Claude / ChatGPT wiring
scripts/     # install.ps1 + install.sh
LICENSE      # free to use; do not sell this pack
```

## Workflows

| Workflow | Use when |
| -------- | -------- |
| `start-branch` | Create a topic branch off the right base |
| `investigate` | Find root cause before patching |
| `implement` | Feature or fix end-to-end |
| `review` | Diff / PR review |
| `fix-ci` | Red pipeline or failing checks |
| `unit-test` | Tests for specific code |
| `annotate` | Public API documentation comments |
| `commit` | Conventional commit + versioning |
| `pr-description` | Paste-ready PR body only |
| `open-pr` | Create or update the GitHub PR |
| `release` | Version, notes, publish steps |

Every prompt has **Goal**, **Steps**, **Done when**, and **Next**.

## Install

### Cursor — user (all your projects)

```powershell
.\scripts\install.ps1 -Scope user
```

```bash
./scripts/install.sh user
```

Writes skills/rules to `~/.cursor/` and points at this pack’s `prompts/` + `rules/` (no project pollution). Restart Cursor afterwards.

### Project (shared with the team)

```powershell
.\scripts\install.ps1 -Scope project -Project C:\path\to\your-app -Adapter cursor
# Adapter: cursor | claude | chatgpt | all
```

```bash
./scripts/install.sh project /path/to/your-app cursor
```

1. Vendors `prompts/` + `rules/` (+ `LICENSE`) into **`.ai-workflows/`**
2. Wires adapters from `adapters/cursor/skills/`
3. Commit `.ai-workflows/` (and `.cursor/` if Cursor) so the team shares one process

Re-run install after updating this pack.

## Design

- One source of truth: `prompts/` + `rules/`
- Thin adapters (path rewrite only)
- Chainable workflows
- Portable across tools and models

## License

See [LICENSE](LICENSE): free to use and share; do not sell this pack as a product.
