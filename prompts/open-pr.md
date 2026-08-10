# Open PR workflow

Create (or update) a GitHub pull request for the current branch with a solid description.

## Goal

A PR URL the team can review: correct base, conventional topic branch, complete description.

## Steps

1. **Preflight**
   - Topic branch should look like `feature/*` · `fix/*` · `hotfix/*` · `refactor/*` · `experiment/*`. If not, warn and offer `start-branch.md` (do not rename silently unless asked).
   - Resolve **base** (same rules as `start-branch.md` / engineering rules): user -> CONTRIBUTING/pipeline -> current release train -> `main`.
   - Current branch != base.
   - Ensure commits exist: `git log <base>..HEAD --oneline`.
   - If no remote tracking branch yet, **ask** before first push (`git push -u origin HEAD`).
   - Never force-push unless explicitly asked.

2. **Description**
   - Same content rules as `pr-description.md` (Summary, Breaking changes, Test plan).
   - English. One concern per PR when practical.

3. **Create or update**
   - Prefer GitHub CLI:
     - Create: `gh pr create --base <base> --title "<title>" --body "<markdown>"`
     - Already open: `gh pr view` / `gh pr edit` as needed.
   - Title: concise; align with main Conventional Commit intent.
   - If `gh` is missing, output paste-ready body + exact commands.

4. **Return**
   - PR URL + `base <- head` + one-line summary of contents.

## Done when

- PR targets the correct integration line (`main` or `release/*`).
- Description has Summary, Breaking changes, Test plan.
- No amend/rebase/`--force` unless requested.

## Next

Human review -> `review.md` if asked -> `release.md` when cutting a release.
