#!/usr/bin/env bash
# scripts/test.sh
#
# Runs the project's test suites:
#   - Python unit tests for the device simulators (devices/tests/unit),
#     the same tests the CI workflow (.github/workflows/ci-cd.yml) runs.
#   - Optionally, the AWS integration tests (devices/tests/integration),
#     gated behind --integration since they require real AWS infra
#     (see the `integration` marker in pytest.ini).
#   - The Go backend test suite (backend/), if Go is installed.
#
# Usage:
#   ./scripts/test.sh                 # unit tests only
#   ./scripts/test.sh --integration   # unit + integration tests
#   ./scripts/test.sh --no-go         # skip the Go backend tests

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

RUN_INTEGRATION=false
RUN_GO=true
for arg in "$@"; do
    case "$arg" in
        --integration) RUN_INTEGRATION=true ;;
        --no-go) RUN_GO=false ;;
        *) echo "Unknown option: $arg" >&2; exit 1 ;;
    esac
done

if [[ -f "$REPO_ROOT/.venv/bin/activate" ]]; then
    # shellcheck disable=SC1091
    source "$REPO_ROOT/.venv/bin/activate"
fi

echo "==> Running Python unit tests (devices/tests/unit)"
pytest devices/tests/unit -v

if [[ "$RUN_INTEGRATION" == true ]]; then
    echo "==> Running Python integration tests (devices/tests/integration)"
    echo "    NOTE: these require real AWS infrastructure to be deployed."
    pytest devices/tests/integration -v -m integration
else
    echo "==> Skipping integration tests (pass --integration to include them)"
fi

if [[ "$RUN_GO" == true ]]; then
    if command -v go >/dev/null 2>&1; then
        echo "==> Running Go backend tests (backend/)"
        (cd "$REPO_ROOT/backend" && go test ./...)
    else
        echo "==> Go not found on PATH — skipping backend tests"
    fi
else
    echo "==> Skipping Go backend tests (--no-go)"
fi
