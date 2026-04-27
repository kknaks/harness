#!/usr/bin/env bash
# Usage: merge.sh <idea-file> <spec-file>
# Append <idea> to <spec>'s `sources` block list. Idempotent.
# Bumps the spec's `updated` field. Run validate.sh afterwards.

set -euo pipefail

IDEA="${1:-}"
SPEC="${2:-}"
[[ -f "${IDEA:-}" && -f "${SPEC:-}" ]] \
  || { echo "usage: $0 <idea-file> <spec-file>" >&2; exit 1; }

IDEA_BASE="$(basename "$IDEA" .md)"

python3 - "$SPEC" "$IDEA_BASE" <<'PY'
import sys, re, datetime, pathlib
spec_path = pathlib.Path(sys.argv[1])
idea_base = sys.argv[2]
text = spec_path.read_text()

if f"[[{idea_base}]]" in text:
    print(f"already merged: {idea_base}", file=sys.stderr)
    sys.exit(0)

m = re.search(r'(?m)^sources:[ \t]*\n((?:[ \t]+-[ \t]+[^\n]*\n)+)', text)
if not m:
    sys.stderr.write(
        "could not find block-form 'sources:' list — edit spec manually.\n"
    )
    sys.exit(2)

new_block = m.group(1) + f'  - "[[{idea_base}]]"\n'
text = text[:m.start(1)] + new_block + text[m.end(1):]

today = datetime.date.today().isoformat()
text = re.sub(r'^updated:.*$', f'updated: {today}', text, count=1, flags=re.M)

spec_path.write_text(text)
print(f"merged: {idea_base} -> {spec_path.stem}")
PY
