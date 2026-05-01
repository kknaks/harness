# Content Map

> 자동 생성. 수동 편집 금지. 재생성: `.claude/skills/docs-validate/scripts/validate.sh`. ADR-0001 §콘텐츠 레이어 인덱스 (메타 `docs/_map.md` 와 평행).

_5단 자산: inbox 3 · sources 3 (pending: 1, promoted: 2) · wiki 2 (promoted: 2) · adr 2 (proposed: 2) · harness 1 (총 11)_

## Categories

- `code-review` — 3
- `test-design` — 3
- `convention-check` — 1
- `tdd` — 1

## Stages

- `inbox/` — 모든 기여자 공용 입구. raw dump
- `sources/` — 1차 가공 = 정체화 (이름·목적 박음, 이후 불변)
- `wiki/` — 합성·정리 (LLM + 인간 검토)
- `adr/` — atomic 결정 (자산-plugin 매핑)
- `harness/` — 배포 (5단 마지막 = distribution monorepo)

레거시 자산 (회사에 흩어진 SKILL/hook/MCP/settings) 은 `inbox/` PR 로 흘러들어옴 → 메인테이너 triage ([[adr-0002-permissions-flow]] §inbox 워크플로우 §4) → 콘텐츠 5단 또는 메타 3단 분기.

_(자산별 풍부 인덱싱은 콘텐츠 단계 frontmatter 명세 박힌 후 보강 — ADR-0004 line 130)_
