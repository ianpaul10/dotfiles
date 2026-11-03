#!/usr/bin/env bash
# Usage: tests/run.sh [spec-file-or-dir]
set -euo pipefail
cd "$(dirname "$0")/.."
target="${1:-tests}"
nvim --headless --noplugin -u tests/minimal_init.lua \
  -c "PlenaryBustedDirectory ${target} { minimal_init = 'tests/minimal_init.lua', sequential = true }"
