#!/usr/bin/env bash
# scripts/lint.sh
#
# Runs the same static analysis used locally via `make lint`:
#   - flake8 over the whole repo (config: .flake8)
#   - pylint over the device simulators and the root orchestrator script
#     (config: .pylintrc)
#
# Usage: ./scripts/lint.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if [[ -f "$REPO_ROOT/.venv/bin/activate" ]]; then
    # shellcheck disable=SC1091
    source "$REPO_ROOT/.venv/bin/activate"
fi

echo "==> flake8 ."
flake8 .

echo "==> pylint devices orchestrator.py"
pylint devices orchestrator.py

echo "==> Lint passed."
