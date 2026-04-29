#!/usr/bin/env bash
# Usage: adr-to-harness.sh <content/adr/adr-NNNN-<slug>.md> <plugin-name>
# Records that a content ADR has been applied to a specific plugin under
# content/harness/plugins/<plugin-name>/. This script does NOT package the
# plugin — packaging is governed by the version-rollout flow (adr-0005:
# CI → dogfood → release tag → autoUpdate). This script only:
#
#   1. Verifies the ADR + plugin directory exist.
#   2. Appends a Notes line in the ADR linking to the plugin (lineage).
#   3. Prints next-step guidance for the release flow.
#
# Plugin packaging (manifest.json, marketplace registration) is the
# responsibility of the maintainer + spec-09 release pipeline, not this
# scaffold script.

set -euo pipefail

ADR="${1:-}"
PLUGIN="${2:-}"
if [[ -z "$ADR" || ! -f "$ADR" ]]; then
  echo "usage: $0 <content/adr/adr-NNNN-<slug>.md> <plugin-name>" >&2
  exit 1
fi
if [[ -z "$PLUGIN" ]]; then
  echo "plugin name required (e.g. base, planning, pm, frontend, backend, qa, infra)" >&2
  exit 1
fi
if [[ ! "$PLUGIN" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  echo "plugin name must be kebab-case: '$PLUGIN'" >&2
  exit 4
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
PLUGIN_DIR="$REPO_ROOT/content/harness/plugins/$PLUGIN"
if [[ ! -d "$PLUGIN_DIR" ]]; then
  echo "plugin directory not found: $PLUGIN_DIR" >&2
  echo "(content/harness/plugins/<plugin>/ must exist before applying an ADR)" >&2
  exit 3
fi

ADR_BASE="$(basename "$ADR" .md)"
TODAY=$(date +%Y-%m-%d)

# append a Notes line linking ADR to plugin (lineage trace)
NOTE="- $TODAY: applied to plugin \`$PLUGIN\` (content/harness/plugins/$PLUGIN/)"

# only append if not already present
if ! grep -qF "applied to plugin \`$PLUGIN\`" "$ADR"; then
  # find ## Notes section and append after the placeholder (or at end)
  if grep -q "^## Notes" "$ADR"; then
    # append to end of file (Notes is the last section)
    printf "%s\n" "$NOTE" >> "$ADR"
  else
    printf "\n## Notes\n\n%s\n" "$NOTE" >> "$ADR"
  fi
fi

cat <<EOF
ADR applied: $ADR_BASE -> plugin/$PLUGIN

Notes appended (lineage trace).

Next steps (NOT handled by this script — see adr-0005 version-rollout):
  1. Update plugin source under: $PLUGIN_DIR/
  2. Bump plugin manifest version.
  3. Tag dogfood release; verify 24h.
  4. Tag release; autoUpdate propagates to all users.
  5. On bad release: force update to previous tag + post-mortem ADR.
EOF
