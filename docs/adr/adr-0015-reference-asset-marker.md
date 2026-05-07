---
id: adr-0015
title: Reference Asset Marker
type: adr
status: proposed
date: 2026-05-03
sources:
  - "[[spec-16-reference-asset-marker]]"
related_to:
  - "[[adr-0007-skill-authoring-rules]]"
  - "[[adr-0011-base-hoisting]]"
  - "[[adr-0014-single-plugin-scaffolder]]"
tags: [adr, promote-docs, reference-asset]
aliases: []
---

# Reference Asset Marker

## Context

승격 원본: `docs/spec/spec-16-reference-asset-marker.md` (idea-09 → spec-16). 콘텐츠 ADR-0009 가 `db-transaction` 을 reference 자산 (절차 SKILL 아님 — 개념·룰·근거 묶음) 으로 결정했지만 promote-docs SKILL 에 reference 처리 절차 부재 → `skills/` 에 잠정 박음 + SKILL.md 첫 줄 "reference 자산" 명시. 본 ADR 이 정식 처리 룰 박는다.

핵심 제약 (idea-09 §Q1 사용자 결정): *평행 디렉토리 X — 한 역할당 변경 surface 폭발 회피*.

## Decision

`skills/<name>/SKILL.md` frontmatter 에 **`asset_type: skill (디폴트) | reference`** enum 마커 박는다. 평행 `references/` 디렉토리·별 sh·별 manifest 필드 *모두 X*. 5개 도구 (`add-role-skill.sh` / `create-skill.sh` / `sync-role-manifest.py` / `validate.sh` / `adr-to-harness.sh`) 가 이 마커 한 줄 보고 분기.

§부속결정:
- **CLI**: `add-role-skill.sh --reference` 플래그 (별 sh X)
- **manifest**: `role.json: skills[].type` 필드 (별 `references[]` X)
- **validate**: reference 는 `checklist.md` + `examples/` 둘 다 *면제*
- **트리거**: link only — slash command 등록 X
- **propagate**: wiki/adr frontmatter 도 `asset_type` 박지만 *순방향* (SKILL→wiki/adr) 는 sh 자동, *역방향* (SKILL.md 수정 시 wiki/adr 갱신) 는 메인테이너 손
- **마이그레이션**: 기존 `db-transaction` SKILL.md frontmatter 1줄 추가 (디렉토리 이동 X)

## Alternatives Considered

| 후보 | 채택 안 한 이유 |
|------|------------------|
| 평행 `references/<name>/` 디렉토리 + 별 `add-role-reference.sh` | 한 역할당 변경 surface 폭발 (sh / manifest 필드 / validate 분기 / 마이그레이션). idea-09 §Q1 사용자 결정 |
| `role.json` 에 `references[]` 신규 필드 | `skills[]` 와 *동일 수명·관리* 인데 별 리스트 = drift 위험. `type` 필드로 통합 |
| reference 도 slash command 등록 | reference = 절차 X = 능동 트리거 X. 자매 SKILL link 로 충분 |
| `is_reference: true` boolean | enum (`asset_type`) 가 확장성 좋음 — 미래 `hook` / `template` 추가 가능 |
| 마커 필드명 `kind` / `category` | `kind` generic / `category` 는 `categories[]` 와 충돌. `asset_type` 명시적 |
| reference 도 `examples/` 최소 1 파일 강제 | OQ-A 답변 — *완전 면제*. 메인테이너 자율 (lookup demo 박고 싶으면 자유) |
| `adr-to-harness.sh` 가 `--reference` 자동 호출 안 함 (메인테이너 수동) | OQ-B 답변 — *자동* 으로 한 손 줄임 |
| 역방향 propagate sh 신설 | OQ-C 답변 — *메인테이너 손*. 역방향은 빈도 낮고 wiki/adr 본문 수정 시 함께 처리 자연스러움 |

## Implementation Path

| Action | 누가 | 언제 | 의존 / 산출 |
|--------|------|------|--------------|
| `asset_type` enum 정의 (`skill` 디폴트 / `reference`) frontmatter 스키마 박기 | 메인테이너 | v0.3 | promote-docs/rules.md 갱신 |
| `add-role-skill.sh --reference` 플래그 추가 | 메인테이너 | v0.3 | sh 변경 |
| `create-skill.sh --reference` 플래그 추가 (scaffold 의 frontmatter 마커 + checklist.md / examples/ 생략 옵션) | 메인테이너 | v0.3 | sh 변경 |
| `sync-role-manifest.py` 가 SKILL.md 의 `asset_type` 읽고 `role.json: skills[].type` sweep | 메인테이너 | v0.3 | python 변경 |
| `validate.sh` (또는 lib) 가 `asset_type: reference` 자산은 `checklist.md` / `examples/` 검증 skip | 메인테이너 | v0.3 | validate 변경 |
| `adr-to-harness.sh` 가 콘텐츠 ADR `asset_type: reference` 발견 시 `--reference` 자동 전달 | 메인테이너 | v0.3 | sh 변경 |
| 기존 `db-transaction/SKILL.md` frontmatter `asset_type: reference` 1줄 추가 | 메인테이너 | v0.3 | 마이그레이션 1 PR |
| 콘텐츠 wiki-09 / adr-0009 frontmatter `asset_type: reference` 1줄 추가 (역방향 메인테이너 손) | 메인테이너 | v0.3 | 동일 PR |
| `sync-role-manifest.sh backend` 재실행 → role.json 갱신 | 메인테이너 | v0.3 | role.json |
| `db-transaction/SKILL.md` 첫 줄 "reference 자산, 절차 SKILL 아님" 잠정 문구 → 정식 description (frontmatter 마커가 정체 박으니 본문 안내문 정리) | 메인테이너 | v0.3 | SKILL.md 정리 |

## Consequences

**Pros**
- *마커 1줄* 로 SKILL ↔ reference 구분. 새 디렉토리·sh·manifest 필드 X — 변경 surface 최소
- enum 확장성 — 미래 `hook` / `template` 같은 자산 종류 추가 시 동일 패턴
- 기존 자산 마이그레이션 비용 0 (디폴트 = `skill`, 필드 누락 시)
- `db-transaction` 잠정 처리 1줄 patch 로 정식 전환

**Cons**
- 메인테이너가 *마커 박기 자체* 잊을 위험 (디폴트 = skill 이라 reference 자산을 SKILL 로 잘못 등록할 수 있음). validate 가 *추측 룰* (description 에 "reference" 단어 있으면 경고) 같은 보강 필요할 수 있음 — Follow-up
- 역방향 propagate 메인테이너 손 → SKILL.md 와 wiki/adr 의 `asset_type` drift 가능. validate 가 *cross-layer* 검증 X (메타 ↔ 콘텐츠 ADR-0009 cross-layer 와 동일 한계)
- `examples/` 면제로 reference 자산이 *예시 없이* 박힐 수 있음 — Claude 가 어떻게 lookup 하는지 사용 패턴 학습 자료 부재 가능

**Follow-ups**
- [ ] `validate.sh` 의 *추측 룰* — description 에 "reference" 등 키워드 있으면 `asset_type` 마커 누락 경고
- [ ] cross-layer drift 검증 — SKILL.md `asset_type` ↔ wiki/adr `asset_type` 일치 검증 sh
- [ ] reference 자산의 lookup 시나리오 모음 — `examples/` 면제지만 *권장 패턴 wiki* 박기 (idea 후보)
- [ ] `db-transaction` 마이그레이션 PR 머지 후 본 ADR `applied` 박기

## Notes

_(시간순 append)_

- 2026-05-03 — proposed. spec-16 → adr-0015. idea-09 §Q1 사용자 결정 (마커 vs 평행 디렉토리) + spec OQ-A/B/C/D 4개 해소 후 승격.
- 2026-05-03 — applied. 5 도구 변경 (`create-skill.sh` / `add-role-skill.sh` `--reference` 플래그 + `sync-role-manifest.py` mixed format + `validate.py` asset_type 분기 + R12 mixed format + `adr-to-harness.sh` ASSET_TYPE 인식) + 3 frontmatter 1줄 추가 (`db-transaction/SKILL.md` / `wiki-09` / `adr-0009`) + role.json 재sweep 완료 → `db-transaction` 이 mixed format 의 첫 reference 자산.
