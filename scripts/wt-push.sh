#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

REMOTE="${1:-origin}"

if ! git -C "$ROOT_DIR" remote get-url "$REMOTE" >/dev/null 2>&1; then
  echo "Remote not configured: $REMOTE"
  exit 1
fi

CURRENT_BRANCH="$(git -C "$ROOT_DIR" branch --show-current)"
if [[ -z "$CURRENT_BRANCH" ]]; then
  echo "No current branch."
  exit 1
fi

git -C "$ROOT_DIR" push "$REMOTE" "$CURRENT_BRANCH"
