#!/usr/bin/env bash
# Shared Hermes environment for native installs.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

export HERMES_HOME="${HERMES_HOME:-$ROOT/data/hermes}"
export VENV_PYTHON="$ROOT/.venv/bin/python"
export PATH="$ROOT/.venv/bin:${HOME}/.local/bin:${PATH}"
