#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <topic-slug>"
  exit 1
fi

TOPIC="$1"
BRANCH="feature/${TOPIC}"

git -C "$ROOT_DIR" checkout main
git -C "$ROOT_DIR" merge --no-ff "$BRANCH" -m "Merge ${BRANCH} into main"
