#!/usr/bin/env bash
set -euo pipefail

# Resolve repo root (works even if you run it from elsewhere)
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "${REPO_ROOT}" ]]; then
  echo "ERROR: This script must be run inside a git repository."
  exit 1
fi

HOOKS_DIR="${REPO_ROOT}/.hooks"

if [[ ! -d "${HOOKS_DIR}" ]]; then
  echo "ERROR: Hooks directory not found: ${HOOKS_DIR}"
  exit 1
fi

# Make hook files executable (only regular files; ignore dirs)
while IFS= read -r -d '' f; do
  chmod +x "$f"
done < <(find "${HOOKS_DIR}" -type f -print0)

# Tell git to use .hooks as hooks folder (local repo config)
git config core.hooksPath ".hooks"

echo "OK: Installed hooks via core.hooksPath=.hooks"
echo "OK: Hooks made executable:"
find "${HOOKS_DIR}" -maxdepth 1 -type f -print | sed 's|^| - |'