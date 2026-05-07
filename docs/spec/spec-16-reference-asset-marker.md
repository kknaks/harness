---
id: spec-16
title: Reference Asset Marker
type: spec
status: draft
created: 2026-05-03
updated: 2026-05-03
sources:
  - "[[idea-09-reference-asset-pipeline]]"
owns: reference-asset-marker
tags: [spec, promote-docs, reference-asset]
aliases: []
---

# Reference Asset Marker

## Scope

`reference 자산` (절차 SKILL 이 아닌 개념·룰·근거 묶음) 을 5단 파이프라인 + plugin role manifest 에서 *마커 1줄* 로 처리하는 룰셋. `skills/<name>/SKILL.md` frontmatter `asset_type` 필드 + 5개 도구 분기 (sh / validate / manifest sync) 를 포괄.

## Summary

`asset_type: skill | reference` 를 SKILL.md frontmatter 에 박고, sh / validate / manifest 가 그 줄 보고 분기. 평행 `references/` 디렉토리 X — 한 역할당 변경 surface 최소화 (idea-09 §Q1 사용자 결정).

## Background

원본: `docs/idea/idea-09-reference-asset-pipeline.md` — `content/adr/adr-0009-db-transaction-to-backend` (콘텐츠 ADR, cross-layer) 가 `db-transaction` 을 reference 자산 (SKILL 아님) 으로 결정했지만 promote-docs SKILL 에 reference 처리 절차 부재 → `skills/` 에 잠정 박음. 본 spec 이 정식 절차 박는 메타 결정.

## Goals

- SKILL 과 reference 자산 *구분 가능* — frontmatter 1줄로 검증·sh·manifest 가 분기
- 변경 surface *최소* — 디렉토리 / sh / manifest 필드 신설 회피, 기존 자산에 마커 추가만
- reference 자산 호출은 *link only* — slash command 등록 안 함 (`SKILL.md description` 도 reference 성격 명시)
- 기존 `db-transaction` 의 잠정 처리를 *1줄 patch* 로 정식 전환

## Non-goals

- 평행 `references/` 디렉토리 신설 — Q1 결정으로 회피
- `add-role-reference.sh` 별도 sh — `add-role-skill.sh --reference` 로 흡수
- reference 자산의 examples 검증 룰 *전면* 재정의 — lookup 시나리오 형태 1종만 허용 (절차 시나리오 X)
- `db-transaction` 외 다른 잠정 reference 자산 마이그레이션 — 본 spec 이후 새로 박는 자산만 마커 강제 + 기존은 best-effort

## Design

### 1. 마커 필드 (frontmatter)

```yaml
---
name: db-transaction
description: 트랜잭션 reference (...)
allowed_tools: [Read]
asset_type: reference   # ← 신규. enum: skill (디폴트) | reference
---
```

- 디폴트 = `skill` (필드 누락 시). 기존 SKILL 들 수정 0.
- enum 외 값 = validate 차단.

### 2. wiki / adr frontmatter propagate

`sources-to-wiki.sh` / `wiki-to-adr.sh` 가 `asset_type` 필드 propagate. 콘텐츠 wiki / 콘텐츠 ADR 에서도 `asset_type: reference` 마크.

```yaml
# content/wiki/wiki-09-db-transaction-reference.md
asset_type: reference
```

→ ADR 단계에서 `adr-to-harness.sh` 가 `asset_type` 보고 `add-role-skill.sh --reference` 로 호출 가능.

### 3. sh 분기

| sh | 변경 | 동작 |
|----|------|------|
| `add-role-skill.sh` | `--reference` 플래그 추가 | SKILL.md frontmatter 에 `asset_type: reference` 박기 |
| `create-skill.sh` | 동일 (`--reference` 전달) | scaffold 의 frontmatter 에 마커 + checklist.md 생성 X (옵션) |
| `sync-role-manifest.py` | `skills[].type` 필드 sweep | `asset_type: reference` 면 `type: reference`, 아니면 `type: skill` (디폴트 생략 가능) |
| `validate.sh` | `asset_type` 분기 | reference 자산은 §4 룰 적용 |
| `adr-to-harness.sh` | `asset_type` propagate 시 `--reference` 자동 호출 | (선택) |

### 4. validate 룰 분기

| 룰 | `asset_type: skill` (디폴트) | `asset_type: reference` |
|----|------------------------------|------------------------|
| `checklist.md` 존재 | 필수 | **면제** (있어도 OK, 없어도 OK) |
| `examples/` 내용 | 절차 시나리오 (`sample-no-reference.md` + `sample-with-reference.md`) | lookup 시나리오 (디버깅 / 의사결정 트리) — 파일명 자유 |
| `allowed_tools` | `Read, Edit, Bash` 표준 | `Read` 만 권장 (코드 변경 X) |
| `description` | 절차 1줄 | "reference (..)" 명시 권장 |

### 5. role.json 매니페스트

```json
{
  "skills": [
    { "name": "entity-add", "description": "..." },
    { "name": "alembic-migration", "description": "..." },
    { "name": "db-transaction", "description": "...", "type": "reference" }
  ]
}
```

- `type` 필드 부재 = `skill` 디폴트.
- `references[]` 별 필드 X.

### 6. 마이그레이션 (기존 `db-transaction`)

```diff
 ---
 name: db-transaction
 description: 트랜잭션 reference (...)
 allowed_tools: [Read]
+asset_type: reference
 ---
```

- SKILL.md frontmatter 1줄 추가.
- `sync-role-manifest.py` 재실행 → `role.json` 갱신.
- 콘텐츠 wiki-09 / adr-0009 도 frontmatter 1줄 추가 (역방향 propagate — 메인테이너 손).

### 7. 트리거 (link only)

- reference 자산은 slash command *등록 X*. `description` 에 "절차 SKILL 아님" 명시.
- 자매 SKILL (entity-add / alembic-migration / refactor-layered) 의 SKILL.md / rules.md 에서 `db-transaction` 1줄 link 로 인용:
  ```markdown
  자세한 commit/flush/rollback 책임 분리는 `db-transaction` reference §rules 참조.
  ```
- Claude 가 자매 SKILL 본문 읽다가 link 만나면 reference 로드.

## Interface

### CLI 변경

```bash
# 새 reference 자산 등록
add-role-skill.sh backend my-ref "..." --reference

# 새 SKILL (디폴트, 변경 없음)
add-role-skill.sh backend my-skill "..."
```

### Frontmatter 스키마

| 필드 | 위치 | enum |
|------|------|------|
| `asset_type` | SKILL.md / wiki / adr | `skill` (디폴트) \| `reference` |

### Role Manifest 스키마

```json
{
  "skills": [
    { "name": "...", "description": "...", "type": "skill" | "reference" }
  ]
}
```

`type` 필드 부재 = `skill`.

## Open Questions (해소)

- [x] **OQ-A.** reference 자산의 `examples/` — **완전 면제**. validate 가 reference 자산이면 `examples/` 검증 skip. (메인테이너가 lookup demo 박고 싶으면 자율 — 강제 X)
- [x] **OQ-B.** `adr-to-harness.sh` 가 `asset_type: reference` 발견 시 — **자동 `--reference` 호출**. 메인테이너 한 손 줄임.
- [x] **OQ-C.** SKILL.md 수정 시 wiki/adr `asset_type` 역방향 propagate — **메인테이너 손** (sh 미신설). 역방향 sh 는 한 번만 쓰일 가능성 높고, wiki/adr 본문 손볼 때 frontmatter 도 같이 박는 게 자연스러움.
- [x] **OQ-D.** 마커 필드명 — **`asset_type`**. `kind` 너무 generic / `category` 는 기존 `categories[]` 와 충돌. `asset_type` 이 명시적 + 어휘 충돌 없음.

## Alternatives Considered

| 대안 | 채택 안 한 이유 |
|------|------------------|
| 평행 `references/` 디렉토리 + 별도 `add-role-reference.sh` | 한 역할당 수정 surface 폭발 (sh / manifest 필드 / validate 분기 / 마이그레이션). idea-09 §Q1 사용자 결정으로 회피 |
| `role.json` 에 `references[]` 신규 필드 | `skills[]` 와 *동일 수명·관리* 인데 별 리스트 = drift 위험. `type` 필드로 통합 |
| reference 도 slash command 등록 | reference = 절차 X = 능동 트리거 X. 자매 SKILL link 로 충분 |
| `is_reference: true` boolean 필드 | enum (`asset_type: skill | reference`) 가 확장성 좋음 (예: 미래에 `hook` / `template` 추가 가능) |
