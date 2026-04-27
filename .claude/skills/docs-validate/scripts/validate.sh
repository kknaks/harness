#!/usr/bin/env bash
# Usage: validate.sh
# Runs all spec/INDEX consistency checks. Exit 0 = pass, 1 = violations.

set -euo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel)"
exec python3 "$(dirname "$0")/validate.py" "$REPO_ROOT"
