#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if command -v node >/dev/null 2>&1; then
  NODE_BIN="$(command -v node)"
elif [ -x "$HOME/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node" ]; then
  NODE_BIN="$HOME/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node"
else
  cat >&2 <<'EOF'
Node.js was not found.

Install Node.js from https://nodejs.org/ or run this inside Codex where the bundled runtime is available.
EOF
  exit 127
fi

exec "$NODE_BIN" "$ROOT/backend/creature-server.cjs"
