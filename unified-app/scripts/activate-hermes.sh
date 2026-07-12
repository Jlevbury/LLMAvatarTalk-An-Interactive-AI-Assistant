#!/usr/bin/env bash
# Source this file to put the native Hermes CLI on your PATH:
#   source unified-app/scripts/activate-hermes.sh
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT/scripts/lib/hermes-env.sh"
echo "Hermes ready (HERMES_HOME=$HERMES_HOME)"
