#!/usr/bin/env bash
# Start Hermes gateway with API server enabled (for AIRI / OpenAI-compatible clients).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# shellcheck disable=SC1091
source "$ROOT/scripts/lib/hermes-env.sh"

if [ ! -x "$VENV_PYTHON" ]; then
  echo "Hermes venv missing. Run: ./scripts/setup-native.sh" >&2
  exit 1
fi

if [ ! -f "$HERMES_HOME/.env" ]; then
  echo "Hermes config missing. Run: ./scripts/setup-native.sh" >&2
  exit 1
fi

if [ ! -f "$HERMES_HOME/auth.json" ] && { [ ! -f "$HERMES_HOME/config.yaml" ] || ! grep -q 'provider: nous' "$HERMES_HOME/config.yaml" 2>/dev/null; }; then
  echo "Nous Portal not configured yet. Run: hermes setup --portal" >&2
  exit 1
fi

echo "Starting Hermes gateway (API: http://127.0.0.1:8642/v1)..."
exec hermes gateway run
