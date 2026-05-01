#!/usr/bin/env bash
# ADR-0006 D-8 collector. install 된 plugin 들의 CLAUDE.md.snippet 조각을 합성해
# 사용자 진입점 메타 (CLAUDE.md / AGENTS.md) 에 마커 블록으로 박는다.
#
# 마커 형식 (ADR-0006 D-3): <!-- medi-docs-managed:start v={ver} --> ... :end -->
# Idempotent — 마커 블록 *내부만* 갱신, 외부 사용자 내용 절대 변경 X.
# 발견 우선순위 (D-6): CLAUDE.md → AGENTS.md → 부재 시 CLAUDE.md 신규.
#
# Usage: medi-claude-md-augment.sh [project-dir]

set -euo pipefail

PROJECT_DIR="${1:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"
PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATES_DIR="$PLUGIN_ROOT/medi-docs-templates"
ROLE_TEMPLATES_DIR="$PLUGIN_ROOT/role-templates"

BASE_SNIPPET="$TEMPLATES_DIR/CLAUDE.md.snippet"
[[ -f "$BASE_SNIPPET" ]] || { echo "base snippet 부재: $BASE_SNIPPET" >&2; exit 1; }

# version (plugin.json 에서 추출, 없으면 0.0)
VERSION=$(grep -E '"version"' "$PLUGIN_ROOT/plugin.json" 2>/dev/null \
          | head -1 | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' || true)
[[ -z "$VERSION" ]] && VERSION='0.0'

# 합성: base snippet 기본 → :slash-list:start 와 :end 사이에 role 별 entries append
TMP=$(mktemp)
trap "rm -f $TMP" EXIT

# 1. base snippet 복사 (마커 블록 헤더 v= 갱신)
sed "s/medi-docs-managed:start v=[^ ]* /medi-docs-managed:start v=$VERSION /" "$BASE_SNIPPET" > "$TMP"

# 2. slash-list 마커 사이에 role plugin 들의 snippet entries 삽입
SLASH_START='<!-- medi-docs-managed:slash-list:start -->'
SLASH_END='<!-- medi-docs-managed:slash-list:end -->'

# 발견된 role plugin 별 snippet 수집 (알파벳순). bash 3.2 호환 — assoc array 회피.
ROLE_LINES=""
CONFLICTS=""
SEEN_SLASHES=""  # space-separated "slash:role slash:role ..."
if [[ -d "$ROLE_TEMPLATES_DIR" ]]; then
  for role_dir in $(ls -d "$ROLE_TEMPLATES_DIR"/*/ 2>/dev/null | sort); do
    [[ -d "$role_dir" ]] || continue
    role=$(basename "$role_dir")
    snippet="$role_dir/CLAUDE.md.snippet"
    [[ -f "$snippet" ]] || continue
    while IFS= read -r line; do
      # `- /<command>` entries 만 채집 (placeholder 코멘트 제외)
      [[ "$line" =~ ^-\ \`?/ ]] || continue
      slash=$(echo "$line" | grep -oE '/[a-zA-Z][a-zA-Z0-9:_-]*' | head -1 || true)
      [[ -z "$slash" ]] && continue
      # 중복 검사
      existing_role=$(echo "$SEEN_SLASHES" | tr ' ' '\n' | grep "^${slash}:" 2>/dev/null | head -1 | cut -d: -f2 || true)
      if [[ -n "$existing_role" ]]; then
        CONFLICTS+="  $slash : $existing_role (kept) vs $role (skipped)"$'\n'
        continue
      fi
      SEEN_SLASHES+="${slash}:${role} "
      ROLE_LINES+="$line"$'\n'
    done < "$snippet"
  done
fi

# 3. base 슬래시 (이미 base snippet 에 박혀있음) + role entries 사이에 삽입.
# bash 3.2 + awk -v 의 multiline 이슈 회피 — file-based.
if [[ -n "$ROLE_LINES" ]]; then
  ROLE_FILE=$(mktemp)
  printf '%s' "$ROLE_LINES" > "$ROLE_FILE"
  awk -v role_file="$ROLE_FILE" -v end_marker="medi-docs-managed:slash-list:end" '
    index($0, end_marker) {
      while ((getline rl < role_file) > 0) print rl
      close(role_file)
    }
    { print }
  ' "$TMP" > "$TMP.2" && mv "$TMP.2" "$TMP"
  rm -f "$ROLE_FILE"
fi

if [[ -n "$CONFLICTS" ]]; then
  printf '%s\n' "" "<!-- medi-docs-managed:conflicts" "$CONFLICTS-->" >> "$TMP"
fi

# 4. 사용자 진입점 메타 발견 (D-6)
TARGETS=()
[[ -f "$PROJECT_DIR/CLAUDE.md" ]] && TARGETS+=("$PROJECT_DIR/CLAUDE.md")
[[ -f "$PROJECT_DIR/AGENTS.md" ]] && TARGETS+=("$PROJECT_DIR/AGENTS.md")
if (( ${#TARGETS[@]} == 0 )); then
  TARGETS+=("$PROJECT_DIR/CLAUDE.md")
  touch "$PROJECT_DIR/CLAUDE.md"
fi

# 5. 각 target 에 마커 블록 idempotent 박기
for target in "${TARGETS[@]}"; do
  if grep -q '<!-- medi-docs-managed:start' "$target" 2>/dev/null; then
    # 기존 블록 교체
    awk -v new_block_file="$TMP" '
      BEGIN { skip = 0 }
      /<!-- medi-docs-managed:start/ {
        while ((getline line < new_block_file) > 0) print line
        close(new_block_file)
        skip = 1
        next
      }
      /<!-- medi-docs-managed:end/ && skip { skip = 0; next }
      !skip { print }
    ' "$target" > "$target.tmp" && mv "$target.tmp" "$target"
  else
    # 신규 append (앞에 빈 줄 보장)
    [[ -s "$target" ]] && tail -c1 "$target" | grep -q '^$' || echo "" >> "$target"
    cat "$TMP" >> "$target"
  fi
  echo "augmented: $target"
done

exit 0
