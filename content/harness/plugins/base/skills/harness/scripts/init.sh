#!/usr/bin/env bash
# Usage: init.sh <role> [role...] [--force]
#
# `harness` plugin 의 role-templates/<role>/ 를 *현재 프로젝트의* `.claude/`
# 로 복사. role-templates 자체는 plugin 의 비활성 영역 — Claude Code 가
# 자동 활성하지 않음. 사용자가 본 init 호출 시에만 프로젝트로 박힘 →
# 그 시점부터 Claude Code 가 *프로젝트 로컬* SKILL 로 인식.
#
# Arguments:
#   <role>    backend / frontend / planner / pm / qa / infra (운영 누적순)
#   --force   기존 .claude/skills/<n>/ 가 있으면 덮어쓰기 (기본은 skip + 경고)
#
# Output: 복사한 자산 목록 + 부동 (skipped) 자산 카운트.
# Exit codes:
#   0 = 성공 (전체/부분)
#   1 = 인자 부족
#   2 = 알 수 없는 role

set -euo pipefail

FORCE=false
ROLES=()
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=true ;;
    -h|--help)
      sed -n '2,/^$/p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *) ROLES+=("$arg") ;;
  esac
done

# Plugin root: scripts → harness skill → skills → base
PLUGIN_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
ROLE_TEMPLATES="$PLUGIN_ROOT/role-templates"

if [[ ${#ROLES[@]} -eq 0 ]]; then
  echo "Usage: $0 <role> [role...] [--force]" >&2
  echo "" >&2
  echo "Available roles:" >&2
  if [[ -d "$ROLE_TEMPLATES" ]]; then
    for d in "$ROLE_TEMPLATES"/*/; do
      [[ -d "$d" ]] || continue
      role=$(basename "$d")
      n_skills=$(find "$d/skills" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
      printf "  %-12s  (%s skill%s)\n" "$role" "$n_skills" "$([ "$n_skills" -eq 1 ] && echo "" || echo "s")" >&2
    done
  fi
  exit 1
fi

PROJECT_DIR="$(pwd)"
TARGET="$PROJECT_DIR/.claude"
mkdir -p "$TARGET/skills"

# depends_on transitive expansion. visited set 으로 중복·cycle 자연 차단.
EXPANDED=()
visit_role() {
  local role="$1"
  for r in "${EXPANDED[@]:-}"; do
    [[ "$r" == "$role" ]] && return
  done
  EXPANDED+=("$role")
  local manifest="$ROLE_TEMPLATES/$role/role.json"
  if [[ -f "$manifest" ]]; then
    local deps
    deps=$(python3 -c "import json; d=json.load(open('$manifest')); print(' '.join(d.get('depends_on', []) or []))" 2>/dev/null || echo "")
    for dep in $deps; do
      visit_role "$dep"
    done
  fi
}
for role in "${ROLES[@]}"; do
  visit_role "$role"
done

# base role auto-include (medi-docs prerequisite — 모든 init 시 자동 추가)
already_has_base=false
for r in "${EXPANDED[@]:-}"; do
  [[ "$r" == "base" ]] && already_has_base=true
done
if ! $already_has_base && [[ -d "$ROLE_TEMPLATES/base" ]]; then
  EXPANDED=("base" "${EXPANDED[@]}")
fi
# expand 결과로 ROLES 교체. 사용자 입력 순서는 무시 (depends-first 자연 정렬은
# 의미 없음 — 모든 role 의 skills 가 별 디렉토리이므로 충돌 없음).
ROLES=("${EXPANDED[@]}")
if [[ ${#EXPANDED[@]} -gt 1 ]]; then
  echo "Resolved roles (incl. depends_on): ${EXPANDED[*]}"
  echo ""
fi

declare -i copied=0 skipped=0

copy_skill() {
  local src="$1" dst="$2"
  if [[ -e "$dst" ]] && ! $FORCE; then
    echo "  ! skip (exists): .claude/skills/$(basename "$dst")"
    skipped=$((skipped + 1))
    return
  fi
  rm -rf "$dst"
  cp -R "$src" "$dst"
  echo "  → .claude/skills/$(basename "$dst")"
  copied=$((copied + 1))
}

echo "Plugin root: $PLUGIN_ROOT"
echo "Project:     $PROJECT_DIR"
echo ""

for role in "${ROLES[@]}"; do
  src="$ROLE_TEMPLATES/$role"
  if [[ ! -d "$src" ]]; then
    echo "Unknown role: $role" >&2
    avail=()
    for d in "$ROLE_TEMPLATES"/*/; do
      [[ -d "$d" ]] && avail+=("$(basename "$d")")
    done
    echo "Available: ${avail[*]}" >&2
    exit 2
  fi
  # role.json manifest 우선 — 명시적 skill 목록. 부재 시 fallback (skills/* 전체 복사).
  manifest="$src/role.json"
  if [[ -f "$manifest" ]]; then
    desc=$(python3 -c "import json; d=json.load(open('$manifest')); print(d.get('description', ''))")
    echo "Role: $role  ($desc)"
    skills_list=$(python3 -c "import json; d=json.load(open('$manifest')); print(' '.join(d.get('skills', [])))")
    if [[ -z "$skills_list" ]]; then
      echo "  (manifest 의 skills[] 비어있음 — 복사할 자산 없음)"
    else
      for name in $skills_list; do
        if [[ ! -d "$src/skills/$name" ]]; then
          echo "  ✗ manifest 가 선언한 skill 이 없음: $src/skills/$name" >&2
          exit 3
        fi
        copy_skill "$src/skills/$name" "$TARGET/skills/$name"
      done
    fi
    # commands 도 manifest 가 선언하면 복사 (v0.2 — backend 는 v0.1 에 미박)
    if python3 -c "import json,sys; d=json.load(open('$manifest')); sys.exit(0 if d.get('commands') else 1)" 2>/dev/null; then
      mkdir -p "$TARGET/commands"
      cmds_list=$(python3 -c "import json; d=json.load(open('$manifest')); print(' '.join(d.get('commands', [])))")
      for cmd in $cmds_list; do
        if [[ -f "$src/commands/$cmd.md" ]]; then
          if [[ -e "$TARGET/commands/$cmd.md" ]] && ! $FORCE; then
            echo "  ! skip (exists): .claude/commands/$cmd.md"
            skipped=$((skipped + 1))
          else
            cp "$src/commands/$cmd.md" "$TARGET/commands/$cmd.md"
            echo "  → .claude/commands/$cmd.md"
            copied=$((copied + 1))
          fi
        fi
      done
    fi
  else
    echo "Role: $role  (no manifest — fallback: copying all skills/*)"
    if [[ -d "$src/skills" ]]; then
      for skill in "$src/skills"/*/; do
        [[ -d "$skill" ]] || continue
        name=$(basename "$skill")
        copy_skill "$skill" "$TARGET/skills/$name"
      done
    fi
  fi
  # role-specific scripts (R4 augment/uninstall 등 — .claude/scripts/ 에 추가)
  # NOTE: role-level hooks 는 박지 않음. ADR-0009/0013 — 모든 hook 책임은 base plugin
  # 의 plugin-level hooks.json (Claude Code 가 plugin enable 시 자동 로드).
  if [[ -d "$src/scripts" ]]; then
    mkdir -p "$TARGET/scripts"
    cp "$src/scripts"/*.sh "$TARGET/scripts/" 2>/dev/null || true
    chmod +x "$TARGET/scripts"/*.sh 2>/dev/null || true
    echo "  → .claude/scripts/  (role script 복사)"
  fi
done

# medi_docs scaffold (처음 셋업 시 — 이미 있으면 no-op, ADR-0008)
if [[ -x "$PLUGIN_ROOT/scripts/scaffold-medi-docs.sh" ]]; then
  echo ""
  echo "medi_docs scaffold:"
  "$PLUGIN_ROOT/scripts/scaffold-medi-docs.sh" "$PROJECT_DIR" 2>&1 | sed 's/^/  /' || true
fi

# R4 augment — SKILL 복사 후 .claude/skills/ introspect 해서 CLAUDE.md 마커 블록 박기 (ADR-0006 D-8)
if [[ -x "$TARGET/scripts/medi-claude-md-augment.sh" ]]; then
  echo ""
  echo "[R4] CLAUDE.md augment:"
  "$TARGET/scripts/medi-claude-md-augment.sh" "$PROJECT_DIR" 2>&1 | sed 's/^/  /' || {
    echo "  ⚠ R4 augment 실패 (CLAUDE.md 마커 블록 박기 못함)" >&2
  }
fi

echo ""
echo "✓ Done. copied=$copied, skipped=$skipped"
if (( skipped > 0 )) && ! $FORCE; then
  echo ""
  echo "기존 파일은 보존됨. 갱신을 원하면 --force 로 재실행:"
  echo "  $0 ${ROLES[*]} --force"
fi
