#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOP_DIR="$(dirname "$ROOT_DIR")"
REPO_NAME="$(basename "$ROOT_DIR")"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <topic-slug>"
  exit 1
fi

TOPIC="$1"
BRANCH="feature/${TOPIC}"
WORKTREE_DIR="${TOP_DIR}/${REPO_NAME}-wt-${TOPIC}"

if git -C "$ROOT_DIR" show-ref --verify --quiet "refs/heads/${BRANCH}"; then
  echo "Branch already exists: ${BRANCH}"
  exit 1
fi

if [[ -e "$WORKTREE_DIR" ]]; then
  echo "Worktree path already exists: $WORKTREE_DIR"
  exit 1
fi

git -C "$ROOT_DIR" worktree add -b "$BRANCH" "$WORKTREE_DIR" main
echo "$WORKTREE_DIR"
