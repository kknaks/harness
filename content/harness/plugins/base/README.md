# harness-base

mediness 사내 공용 하네스의 **base plugin**. 모든 role plugin (planner/pm/frontend/backend/qa/infra) 의 의존 — base 가 깔리면 7 role 모두 공통 자산 받음.

## 자산

| 위치 | 역할 |
|------|------|
| `plugin.json` | manifest (autoUpdate, hook 등록 진입) |
| `hooks/hooks.json` | H1 medi_docs 자동 검증 · H4 시크릿 차단 · H5 환경 검증 (ADR-0009 §1) |
| `skills/harness/` | 사용자 onboarding 단일 진입점 (ADR-0006) |
| `medi-docs-templates/` | 9 카테고리 README + template — 사용자 cwd scaffold 자산 (ADR-0008 §1) |

## Uninstall 안내

`claude plugin uninstall harness-base` 시:

- plugin 자산 (hooks / skills / templates) 모두 제거됨
- `~/.claude/settings.json` 의 `enabledPlugins` 에서 자동 제거됨
- 사용자 cwd 의 **`medi_docs/` 는 사용자 자산이라 보존**. 필요 시 직접 삭제 (`rm -rf medi_docs/`).

> Claude Code plugin manifest 가 uninstall hook native 미지원 — 본 README 안내로 대체 (ADR-0008 §5).

## 사용자 흐름

1. `claude plugin marketplace add github:medisolve/harness`
2. `claude plugin install harness-base` (필요 role plugin 도 함께)
3. `/harness` skill 호출 → 상태 확인 + 처음 셋업 분기 → `medi_docs/current/` 9 카테고리 scaffold

## 더 보기

- mediness 전체 구조: harness repo `docs/_map.md` (메타) + `content/_map.md` (콘텐츠 5단)
- 결정 박제: `docs/adr/` (메타 ADR — 모델·정책)
- 자산-plugin 매핑: `content/adr/` (콘텐츠 ADR — 운영 시 가동)
