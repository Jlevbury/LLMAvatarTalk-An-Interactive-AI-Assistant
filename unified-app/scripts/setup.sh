#!/usr/bin/env bash
# One-time setup for the Hermes Agent + AIRI unified app.
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Initializing vendored submodules (hermes-agent, airi)..."
git submodule update --init --recursive

if [ ! -f .env ]; then
  echo "==> Creating .env from .env.example..."
  cp .env.example .env
  if command -v openssl >/dev/null 2>&1; then
    key="$(openssl rand -hex 32)"
    # Portable in-place edit (GNU and BSD sed differ on -i)
    sed "s/^API_SERVER_KEY=$/API_SERVER_KEY=${key}/" .env > .env.tmp && mv .env.tmp .env
    echo "    Generated a random API_SERVER_KEY."
  else
    echo "    NOTE: set API_SERVER_KEY in .env before starting (openssl not found)."
  fi
  # Own the Hermes data dir as the current user so it stays editable.
  {
    echo "HERMES_UID=$(id -u)"
    echo "HERMES_GID=$(id -g)"
  } >> .env
else
  echo "==> .env already exists, leaving it untouched."
fi

mkdir -p data/hermes

cat <<'EOF'

Setup complete. Next steps:

  1. Configure your LLM provider for Hermes (one-time). Either:
       - run the interactive wizard in the container:
           docker compose run --rm hermes setup
       - or edit data/hermes/config.yaml + data/hermes/.env by hand
         (see vendor/hermes-agent/README.md).

  2. Build and start the stack:
       docker compose up -d --build
     (first build takes a while: it builds both Hermes and the AIRI web app)

  3. Open AIRI at http://localhost:6620 and add Hermes as a provider:
       Settings -> Providers -> OpenAI Compatible
         Base URL: http://localhost:8642/v1/
         API key:  the API_SERVER_KEY from unified-app/.env
     Then pick the "hermes-agent" model under Settings -> Modules ->
     Consciousness.

See unified-app/README.md for details and troubleshooting.
EOF
