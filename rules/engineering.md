# Engineering standards

Always-on rules for any assistant in a project using this pack.

## Mindset

Replace slow, inconsistent busywork; do not invent process.
Be decisive and precise. Prefer action over essays.

## Defaults

- Prefer **small, focused** changes. No unrelated refactors.
- Match existing patterns, naming, and tooling in the repo.
- Do not invent APIs, configs, or dependencies when a convention already exists.
- Prefer the repo's **CONTRIBUTING.md**, **AGENTS.md**, or pipeline docs when present; they win over generics here.
- Read enough context before editing. If blocked by ambiguity, ask **once**, then proceed.
- Never commit secrets, tokens, or `.env` files.
- Do not force-push shared branches or skip hooks unless the user explicitly asks.
- Prefer portable commands. On Windows PowerShell, chain with `;` not `&&`.
- Parallelize independent reads/commands; do not narrate tool use.

## Git conventions

### Topic branches

Name topic branches with a type prefix (kebab-case slug after the slash):

| Prefix | Use |
| ------ | --- |
| `feature/` | New capability |
| `fix/` | Bug fix |
| `hotfix/` | Urgent production fix |
| `refactor/` | Restructure without intended behavior change |
| `experiment/` | Spike / try-out (when the repo allows it) |

Examples: `feature/portal-menu`, `fix/auth-timeout`, `hotfix/db-pool`.

Do **not** invent a `dev` integration branch. Do **not** invent prefixes outside this set unless the project docs say otherwise.

### Base / integration line

- Default stable line: **`main`**.
- Some repos use release trains (`release/**`). Topic branches PR into the **active train** when docs say so, not always `main`.
- Resolve base in this order:
  1. User-specified base
  2. Project CONTRIBUTING / pipeline docs
  3. If already on a `release/*` branch, that train
  4. `main` (or `origin/HEAD`)

### Commits and PRs

- Commit messages and PR text in **English**, Conventional Commits.
- Do not amend commits you did not create in this session, or commits already pushed, unless the user explicitly requests it.
- Do not push unless asked.
- One concern per PR when practical.

## Quality bar

- After non-trivial edits, run the project's usual checks when available (hooks, verify/lint/test scripts).
- Fix failures you caused. Do not expand into unrelated breakage without asking.
- Leave touched files clean; no debug leftovers.

## Daily loop

When the task matches a workflow, **read and follow** `.ai-workflows/prompts/<name>.md` (or this pack's `prompts/`):

| Phase | Prompt | Default next |
| ----- | ------ | ------------ |
| New topic branch | `start-branch.md` | `implement.md` |
| Unclear bug / failure | `investigate.md` | `implement.md` or `fix-ci.md` |
| Build feature / fix | `implement.md` | `review.md` |
| Review changes | `review.md` | `implement.md` or `commit.md` |
| Red CI | `fix-ci.md` | `commit.md` |
| Save work | `commit.md` | `open-pr.md` |
| Open / describe PR | `open-pr.md` / `pr-description.md` | human review |
| Ship | `release.md` | - |
| Tests only | `unit-test.md` | `commit.md` |
| Docs on APIs | `annotate.md` | `commit.md` |

Do **not** invent a parallel process. Chain workflows when the user asks (for example "commit and open a PR").
