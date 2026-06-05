#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <topic-slug> [remote]"
  exit 1
fi

TOPIC="$1"
REMOTE="${2:-origin}"
BRANCH="feature/${TOPIC}"
WORKTREE_DIR="$(dirname "$ROOT_DIR")/$(basename "$ROOT_DIR")-wt-${TOPIC}"

git -C "$ROOT_DIR" checkout main
git -C "$ROOT_DIR" merge --no-ff "$BRANCH" -m "Merge ${BRANCH} into main"

if git -C "$ROOT_DIR" remote get-url "$REMOTE" >/dev/null 2>&1; then
  git -C "$ROOT_DIR" push "$REMOTE" main
  git -C "$ROOT_DIR" push "$REMOTE" "$BRANCH"
else
  echo "Remote not configured: $REMOTE"
fi

if git -C "$ROOT_DIR" worktree list | grep -Fq "$WORKTREE_DIR"; then
  git -C "$ROOT_DIR" worktree remove "$WORKTREE_DIR"
fi

git -C "$ROOT_DIR" branch -d "$BRANCH" || true
