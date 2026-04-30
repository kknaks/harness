---
description: harness plugin 설치 상태 + 현재 프로젝트의 .claude/skills/ 자산 점검
allowed-tools: [Bash]
---

User invoked `/harness:status`. 본 slash command 는 harness plugin install 위치 + 사용 가능한 role 목록 + 현재 프로젝트의 `.claude/skills/` 박힌 자산을 보고.

## Action

```bash
# init.sh 경로로부터 plugin root 역추적
INIT_SH=$(find ~/.claude/plugins -type f -name "init.sh" -path "*/skills/harness/scripts/*" 2>/dev/null | head -1)

if [[ -z "$INIT_SH" ]]; then
  echo "harness plugin 의 init.sh 를 찾지 못했습니다 — install 깨졌거나 미설치." >&2
  echo "  /plugin install harness && /reload-plugins" >&2
  exit 1
fi

# init.sh = <plugin>/skills/harness/scripts/init.sh
# <plugin> = init.sh 의 4단계 상위
PLUGIN_ROOT="$(cd "$(dirname "$INIT_SH")/../../.." && pwd)"

echo "=== plugin 설치 상태 ==="
echo "OK: harness plugin"
echo "  root:    $PLUGIN_ROOT"
echo "  init.sh: $INIT_SH"
echo ""

echo "=== 사용 가능한 role ==="
ROLE_TEMPLATES="$PLUGIN_ROOT/role-templates"
if [[ -d "$ROLE_TEMPLATES" ]]; then
  for d in "$ROLE_TEMPLATES"/*/; do
    [[ -d "$d" ]] || continue
    role=$(basename "$d")
    n_skills=$(find "$d/skills" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
    printf "  - %-12s (%s skill%s)\n" "$role" "$n_skills" "$([ "$n_skills" -eq 1 ] && echo "" || echo "s")"
  done
else
  echo "  (role-templates/ 없음 — plugin 가 deprecated 됐거나 잘못 설치됨)"
fi
echo ""

echo "=== 현재 프로젝트 .claude/skills/ ==="
if [[ -d ".claude/skills" ]] && [[ -n "$(ls .claude/skills/ 2>/dev/null)" ]]; then
  ls .claude/skills/ | sed 's/^/  - /'
else
  echo "  (없음 — /harness:init <role> 으로 셋업)"
fi
echo ""

echo "=== medi_docs/current/ ==="
if [[ -d "medi_docs/current" ]]; then
  n_cats=$(find medi_docs/current -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
  echo "  $n_cats 카테고리 박힘"
else
  echo "  (없음 — /harness:init 시 자동 박힘)"
fi
```

## 결과 보고

스크립트 출력을 사용자에게 그대로 전달. 셋업이 안 된 부분이 있으면 다음 호출 예시 제안 (예: 프로젝트 .claude/skills/ 가 비어있으면 `/harness:init backend`).
