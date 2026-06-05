# Worktree Convention

## Branch Names

- `main`: stable baseline only
- `feature/<topic>`: active feature worktrees
- `fix/<topic>`: bug-fix worktrees
- `chore/<topic>`: maintenance-only worktrees

Use lowercase kebab-case for `<topic>`.

## Directory Names

- Keep the primary repo at `/Users/tao/Projects/WeReadScreenSaver`
- Keep worktree directories beside it with the suffix `-dev` or `-wt-<topic>`
- Prefer one worktree per active branch

Current setup:

- `main` -> repo root
- `feature/we-read-screen-saver` -> sibling worktree directory

## Suggested Workflow

1. Keep `main` clean and release-ready.
2. Create a feature worktree with `scripts/wt-start.sh <topic>`.
3. Do all implementation work in that feature worktree.
4. Merge back with `scripts/wt-finish.sh <topic> [remote]`.
5. Push only after merge passes verification.
6. Remove the worktree when the branch is merged or abandoned.

## Automation Contract

Default branch flow:

- Request branch: `feature/<topic>`
- Development worktree: `../WeReadScreenSaver-wt-<topic>`
- Merge target: `main`
- Push order: `main` first, then the feature branch

If a remote is configured, `scripts/wt-finish.sh` pushes both branches automatically.
If no remote exists yet, it stops after the local merge and tells you.

## Useful Commands

```bash
git worktree add ../WeReadScreenSaver-dev -b feature/we-read-screen-saver
git worktree list
git worktree remove ../WeReadScreenSaver-dev
git branch -d feature/we-read-screen-saver
```

Preferred commands:

```bash
scripts/wt-start.sh my-topic
scripts/wt-finish.sh my-topic origin
```
