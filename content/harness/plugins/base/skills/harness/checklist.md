# Harness Checklist

## 모든 시나리오 공통 — Pre-flight

- [ ] `claude plugin list` 실행 → 현재 설치 상태 보고
- [ ] `~/.claude/settings.json` 존재 + 백업 가능 위치 확인
- [ ] 사용자 의도 1줄로 정리 → 시나리오 1-6 중 하나 매칭
  - 모호 시 → 시나리오 1 (상태 확인) fallback

---

## 시나리오 2: 처음 셋업

### Pre-flight

- [ ] 사용자 role 합의 (`base|planner|pm|frontend|backend|qa|infra` 중 1+)
- [ ] cwd 가 의도한 프로젝트 root 인지 사용자 확인 (`medi_docs/current/` 박힐 위치)

### Install (dry-run → 동의)

- [ ] dry-run 보고: "다음 명령 실행 예정: `claude plugin install medi-{role}`"
- [ ] 사용자 Yes 동의 후 실행
- [ ] exit code + 설치된 plugin 목록 보고

### Scaffold

- [ ] `scripts/scaffold-medi-docs.sh` 호출
- [ ] 9 카테고리 박힘 확인 (이미 존재 시 no-op 보고)
- [ ] 사용자에게 `medi_docs/current/` 경로 + 다음 단계 가이드

### Post-flight

- [ ] `claude plugin list` 재실행 → 셋업 후 상태 보고

---

## 시나리오 3-4: 역할 변경 / 다중 역할

### Pre-flight

- [ ] 현재 설치 role + 변경 의도 명시 확인
- [ ] 기존 medi_docs 데이터 보존 여부 확인 (uninstall 해도 medi_docs 는 그대로)

### Change (dry-run → 동의)

- [ ] dry-run 보고:
  - 역할 변경: "기존 medi-{old} uninstall + medi-{new} install"
  - 다중 역할: "medi-{additional} install"
- [ ] 사용자 Yes 동의 후 실행

### Post-flight

- [ ] `claude plugin list` → 변경 후 상태 보고

---

## 위반 / 실패 처리

- `claude plugin install` 실패 → 부분 설치 상태 가능성. 시나리오 1 (상태 확인) 재실행으로 진단.
- `~/.claude/settings.json` 수정 후 Claude Code 재시작 필요 시 사용자에게 안내.
- 시크릿 분실 (`HARNESS_GITHUB_TOKEN` 등) → harness 가 보관 X. 사용자가 셸 rc / keychain 에서 재박기.
