#!/usr/bin/env bash
# scripts/setup.sh
#
# One-shot local dev setup for the Fleexa IoT device simulators.
# - Verifies Python 3.11 is available
# - Creates a virtualenv at repo root (.venv)
# - Installs dev dependencies (requirements-dev.txt)
# - Copies devices/.env.example to devices/.env if one doesn't exist yet
#
# Usage: ./scripts/setup.sh   (run from anywhere; paths are resolved
#                              relative to the repo root)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "==> Checking for Python 3.11..."
PYTHON_BIN=""
for candidate in python3.11 python3 python; do
    if command -v "$candidate" >/dev/null 2>&1; then
        version="$("$candidate" -c 'import sys; print("%d.%d" % sys.version_info[:2])')"
        if [[ "$version" == "3.11" ]]; then
            PYTHON_BIN="$candidate"
            break
        fi
    fi
done

if [[ -z "$PYTHON_BIN" ]]; then
    echo "ERROR: Python 3.11 not found (this project targets 3.11, matching"
    echo "       devices/Dockerfile and the CI workflow). Install it and re-run."
    exit 1
fi
echo "    Using $($PYTHON_BIN --version) ($PYTHON_BIN)"

VENV_DIR="$REPO_ROOT/.venv"
if [[ ! -d "$VENV_DIR" ]]; then
    echo "==> Creating virtualenv at $VENV_DIR"
    "$PYTHON_BIN" -m venv "$VENV_DIR"
else
    echo "==> Virtualenv already exists at $VENV_DIR, reusing it"
fi

echo "==> Installing dependencies from requirements-dev.txt"
"$VENV_DIR/bin/pip" install --upgrade pip
"$VENV_DIR/bin/pip" install -r "$REPO_ROOT/requirements-dev.txt"

ENV_EXAMPLE="$REPO_ROOT/devices/.env.example"
ENV_FILE="$REPO_ROOT/devices/.env"
if [[ -f "$ENV_EXAMPLE" && ! -f "$ENV_FILE" ]]; then
    echo "==> Creating devices/.env from devices/.env.example"
    cp "$ENV_EXAMPLE" "$ENV_FILE"
    echo "    Edit devices/.env and add your AWS credentials before running the simulators."
else
    echo "==> devices/.env already exists (or no example found) — leaving it as-is"
fi

cat <<'EOF'

==> Setup complete. Next steps:
    1. Activate the virtualenv:      source .venv/bin/activate
    2. Populate devices/.env with your AWS credentials (if not already done)
    3. Run the unit tests:           ./scripts/test.sh
    4. Start the simulators locally: make docker-up   (or: cd devices && docker compose up --build -d)
EOF
