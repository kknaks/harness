---
id: idea-09
type: idea
status: open
created: 2026-05-03
tags: [idea, promote-docs, reference-asset]
---

# reference-asset-pipeline

reference 자산 (절차 SKILL 이 아닌 개념·룰·근거 묶음) 의 5단 파이프라인 정식 처리.

## 발생 맥락

`content/adr/adr-0009-db-transaction-to-backend` (콘텐츠 ADR — cross-layer, sources 그래프 외) 가 `db-transaction` 을 *reference 자산* (SKILL 아님) 으로 결정했지만, promote-docs SKILL 에 reference 처리 절차 부재 → `skills/` 디렉토리에 잠정 박음 + SKILL.md 첫 줄에 "reference 자산, 절차 SKILL 아님" 명시. 콘텐츠 ADR-0009 §Follow-up 으로 박힌 후속 결정 → 메타 영역에서 promote-docs SKILL 수정 결정 필요.

## 핵심 차이 (SKILL vs Reference)

| 측면 | SKILL | Reference |
|------|-------|-----------|
| 트리거 | 능동적 작업 (`/skill-name <args>`) | 다른 SKILL 호출 중 lookup |
| 본문 | 절차 (Pre-flight / Action / Post-flight) | 개념 + 룰 + 근거 |
| 산출물 | 코드 변경 / 보고서 | 정보 제공만 |
| 디렉토리 | `skills/<name>/` | `references/<name>/` (제안) |
| manifest | `role.json: skills[]` | `role.json: references[]` (신규 필드 제안) |

## 결정 (Q1 사용자 답변 → 나머지 연쇄)

**Q1 핵심 결정**: `skills/<name>/SKILL.md` frontmatter 에 **`asset_type: reference` 마커** 박기. 평행 `references/` 디렉토리 X.

**근거** (사용자): *평행 디렉토리는 한 역할에 대한 수정 사항이 많아진다* — 새 sh / manifest 필드 / validate 분기 / 기존 자산 마이그레이션 등 surface 폭발. 마커 파일은 SKILL.md frontmatter 한 줄 + sh/validate 가 그 줄 보고 분기 → 변경 최소.

| # | 답변 | 비고 |
|---|------|------|
| Q1 | `skills/<name>/` 그대로 + SKILL.md frontmatter `asset_type: skill \| reference` 마커 | 평행 디렉토리 X |
| Q2 | `add-role-skill.sh --reference` 플래그 (별 sh X) | Q1 결정에 끌려옴. 별 sh = surface 더 늘어남 |
| Q3 | wiki/adr frontmatter `asset_type` 전파 | sh 가 wiki→adr→harness 흐름에서 마커 propagate |
| Q4 | reference 는 `checklist.md` *면제* + `examples/` 는 *lookup 시나리오* (entity-add 의 절차 시나리오 형태 X) | validate 가 `asset_type: reference` 보고 룰 분기 |
| Q5 | `role.json` 의 `skills[]` 안 각 항목에 `type` 필드 | 별 `references[]` 필드 X. Q1 정합 |
| Q6 | 기존 `db-transaction` 의 SKILL.md frontmatter 에 `asset_type: reference` 추가 | 디렉토리 이동 X. 1줄 patch |
| Q7 | **link only** (자매 SKILL 본문에서 link) — slash command X | reference = 절차 X = 명령어 트리거 X. SKILL 명령어 등록 안 함 |

## 작업 가정 (spec 단계 회수 가능)

| 항목 | 기본 가정 | 회수 조건 |
|------|----------|----------|
| 마커 필드명 | `asset_type` | spec 단계에서 `kind` / `category` 더 자연스러우면 변경 |
| frontmatter 위치 | SKILL.md 만 | wiki/adr 도 propagate 하지만 *원천* 은 SKILL.md (5단 역방향) |
| validate 메시지 | `asset_type: reference` 자산은 `checklist.md` 검증 skip | reference 도 *최소* checklist 강제하면 lookup 시나리오 트리만 |

## 영향 범위 (변경 surface — Q1 결정 후 최소화)

- `.claude/skills/promote-docs/scripts/add-role-skill.sh` — `--reference` 플래그 처리 (frontmatter 박을 때 `asset_type` 추가)
- `.claude/skills/promote-docs/scripts/create-skill.sh` — 동일
- `.claude/skills/promote-docs/scripts/sync-role-manifest.py` — `skills[]` 항목에 `type` 필드 박기
- `.claude/skills/docs-validate/scripts/validate.sh` (또는 lib) — `asset_type: reference` 분기
- `content/harness/plugins/base/role-templates/backend/skills/db-transaction/SKILL.md` — frontmatter 1줄 추가 (마이그레이션)

## 다음 단계

idea 결정 종료. 단일 spec 권장: `reference-asset-marker` (마커 + sh 플래그 + validate 분기 + manifest 확장 한 spec).
