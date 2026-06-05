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

- `main` -> `/Users/tao/Projects/WeReadScreenSaver`
- `feature/we-read-screen-saver` -> `/Users/tao/Projects/WeReadScreenSaver-dev`

## Suggested Workflow

1. Keep `main` clean and release-ready.
2. Do feature work in a separate worktree.
3. Merge back only after the feature branch is stable and verified.
4. Remove the worktree when the branch is merged or abandoned.

## Useful Commands

```bash
git worktree add ../WeReadScreenSaver-dev -b feature/we-read-screen-saver
git worktree list
git worktree remove ../WeReadScreenSaver-dev
git branch -d feature/we-read-screen-saver
```
