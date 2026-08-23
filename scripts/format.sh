#!/usr/bin/env bash
# scripts/format.sh
#
# Formats the Python code in this repo with black (config: pyproject.toml,
# [tool.black]). Also runs a non-mutating gofmt check over the Go backend
# so formatting issues there are surfaced (but not auto-rewritten) here.
#
# Usage: ./scripts/format.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if [[ -f "$REPO_ROOT/.venv/bin/activate" ]]; then
    # shellcheck disable=SC1091
    source "$REPO_ROOT/.venv/bin/activate"
fi

echo "==> black ."
black .

if command -v gofmt >/dev/null 2>&1; then
    echo "==> gofmt -l ./backend (check only, does not modify files)"
    UNFORMATTED="$(gofmt -l "$REPO_ROOT/backend")"
    if [[ -n "$UNFORMATTED" ]]; then
        echo "The following Go files are not gofmt-formatted:"
        echo "$UNFORMATTED"
        echo "Run: gofmt -w <file> to fix, or 'go fmt ./...' from backend/"
    else
        echo "    backend/ is gofmt-clean."
    fi
else
    echo "==> gofmt not found on PATH — skipping Go format check"
fi
