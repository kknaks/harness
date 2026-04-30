#!/usr/bin/env bash
# merge-sources-to-wiki.sh — N sources → 기존 wiki 의 sources 에 추가 합치기.
# Usage: merge-sources-to-wiki.sh <sources-file> <wiki-file>
#
# Idempotent. wiki 의 frontmatter `sources:` 블록에 sources lineage 추가.
# wiki 본문 (Summary / Synthesis / References) 합성은 Claude (메인테이너) 책임 — ADR-0012 §1.
# merge.sh (idea→spec) 패턴을 wiki 단계에 적용.

set -euo pipefail

SRC="${1:-}"
WIKI="${2:-}"
[[ -f "${SRC:-}" && -f "${WIKI:-}" ]] \
  || { echo "usage: $0 <sources-file> <wiki-file>" >&2; exit 1; }

SRC_BASE="$(basename "$SRC" .md)"

python3 - "$WIKI" "$SRC_BASE" <<'PY'
import sys, re, pathlib
wiki_path = pathlib.Path(sys.argv[1])
src_base = sys.argv[2]
text = wiki_path.read_text()

if f"[[{src_base}]]" in text:
    print(f"already merged: {src_base}", file=sys.stderr)
    sys.exit(0)

m = re.search(r'(?m)^sources:[ \t]*\n((?:[ \t]+-[ \t]+[^\n]*\n)+)', text)
if not m:
    sys.stderr.write(
        "could not find block-form 'sources:' list — edit wiki manually.\n"
    )
    sys.exit(2)

new_block = m.group(1) + f'  - "[[{src_base}]]"\n'
text = text[:m.start(1)] + new_block + text[m.end(1):]

wiki_path.write_text(text)
print(f"merged: {src_base} -> {wiki_path.stem}")
PY

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/lib/update-status.py" "$SRC" promoted 2>/dev/null || true
