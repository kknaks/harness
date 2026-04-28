#!/usr/bin/env bash
# PostToolUse hook: when Write/Edit modifies a file under docs/idea/, docs/spec/,
# or docs/adr/, run docs-validate. Always exits 0 — validate's stdout/stderr is
# the feedback.

set -uo pipefail

input=$(cat)
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')

case "$file_path" in
  */docs/idea/*|*/docs/spec/*|*/docs/adr/*)
    cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
    [[ -n "$cwd" ]] && cd "$cwd" 2>/dev/null
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ -n "$repo_root" && -x "$repo_root/.claude/skills/docs-validate/scripts/validate.sh" ]]; then
      "$repo_root/.claude/skills/docs-validate/scripts/validate.sh"
    fi
    ;;
esac

exit 0
