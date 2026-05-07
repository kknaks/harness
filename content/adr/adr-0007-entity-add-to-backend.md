---
id: adr-0007
title: Entity Add To Backend
type: adr
status: proposed
date: 2026-05-03
sources:
  - "[[wiki-07-entity-add-pattern]]"
tags: [adr]
categories: [db-design, entity-lifecycle]
role: backend
related_to:
  - "[[adr-0003-api-design-to-backend]]"
  - "[[adr-0004-tdd-cycle-to-backend]]"
  - "[[adr-0005-refactor-layered-to-backend]]"
  - "[[adr-0008-alembic-migration-to-backend]]"
  - "[[adr-0009-db-transaction-to-backend]]"
aliases: []
---

# Entity Add To Backend

## Context

승격 원본: `content/wiki/wiki-07-entity-add-pattern.md` (sources-05 의 entity-add 5단 + Pydantic 스키마 부분 합성). wiki 두 층 — 공용 골격 (5단 절차 + 산출물 + 검증 + 동기화 룰 + grep 검출 흔한 실수) + NEXUS 슬롯 (`server/app/{models,schemas,repositories}/` 위치 + `BaseEntity` 패턴 + `BaseRepository[X]` 상속 + Pydantic v2 `ConfigDict(from_attributes=True)`).

자매 SKILL: `api-design` (adr-0003) = 엔드포인트 단위의 *짝* — 본 SKILL 은 *데이터/엔티티 단위*. `tdd-cycle` (adr-0004) = 5단계 Test 의 사이클 도구. `refactor-layered` (adr-0005) = 4계층 책임표를 *생성 시점* 에 적용. `alembic-migration` (adr-0008) = 2단계 Migration 본체 상세 (별 SKILL). `db-transaction` (adr-0009) = `refresh=False` / `commit` 책임 *근거 reference*.

## Decision

backend role plugin 의 신규 SKILL `entity-add` 본문에 **공용 골격만** — 5단 절차표 + 동기화 룰 (Model+Alembic 한 commit) + grep 검출 흔한 실수 5종. NEXUS 의 디렉토리 위치 / `BaseEntity` 패턴 / `BaseRepository` 헬퍼 / Pydantic v2 어노테이션은 *reference 로드* (`backend.md` / `plan/erd/table-design.md` / 사용처 `<models-dir>` 등), 부재 시 *role-generic fallback* (Spring `@Entity` / Django `models.Model` / TypeORM `@Entity` 등 ORM 디렉토리 자동 추정 + 사용자 확인).

§부속결정:
- **Pydantic 스키마 설계는 별 SKILL 분리 X** — entity-add 의 3단계로 흡수 (sources-05 보강 (d) 권장).
- **Migration 단계는 1줄 참조** — 본 SKILL 은 *호출처* 만, 실제 절차는 `alembic-migration` SKILL (adr-0008).

## Alternatives Considered

| 후보 | 채택 안 한 이유 |
|------|------------------|
| 공용 골격 + NEXUS 슬롯 *합쳐서* role plugin 본문에 박기 | wiki 두 층 분리 무효화. role-generic 의미 자기모순 (promote-docs §자산 분리 룰) |
| `api-design` (adr-0003) 에 흡수 (엔드포인트 + 엔티티 통합) | 트리거가 다름 — api-design = 새 엔드포인트 / entity-add = 새 엔티티(데이터). 한 PR 안에 *둘 다* 발생하지만 *순서가 있음* (엔티티 먼저 → 엔드포인트). 별 SKILL 유지 |
| Pydantic 스키마를 별 SKILL 로 분리 | 분량 작음 (3단계 안 4-5줄). 단독 SKILL 의 *재현 가능 절차* 가 없음. entity-add 흡수가 정합 |
| Migration 까지 entity-add 안에 통합 | Migration 은 *엔티티 추가 외에도* 단독 작업 (스키마 변경 / FK 추가 / 인덱스 등) 빈번. 별 SKILL `alembic-migration` 분리 |
| `tdd-cycle` (adr-0004) 의 Red 단계에 흡수 | tdd-cycle = *어떤 코드든* TDD. entity-add = *데이터 단위 5단 절차*. 결정 단위 다름 |

## Implementation Path

| Action | 누가 | 언제 | 의존 / 산출 |
|--------|------|------|--------------|
| `entity-add` SKILL 본문 (5단 절차 + 동기화 룰 + grep 흔한 실수) | 메인테이너 | v0.2+ | wiki-07 → SKILL.md / rules.md |
| reference 로드 (`backend.md` / `plan/erd/table-design.md` / `database-rules.md` / 사용처 `<models-dir>`) | 메인테이너 | v0.2+ | rules.md |
| role-generic fallback (Spring `@Entity` / Django models / TypeORM 등 ORM 자동 추정) | 메인테이너 | v0.2+ | rules.md §fallback |
| Pydantic 스키마 패턴 박기 (3단계 안) — Request/Response 분리 + `from_attributes=True` + `model_validate(orm)` + 부분 업데이트 (`refresh=False`) | 메인테이너 | v0.2+ | SKILL.md §3 |
| examples 두 개 (단일 엔티티 / 관계 있는 엔티티) | 메인테이너 | v0.2+ | examples/ |
| `add-role-skill.sh backend entity-add "..."` | 메인테이너 | v0.2+ | role.json |
| `adr-to-harness.sh ... backend` Notes | 메인테이너 | v0.2+ | 본 ADR Notes |
| (옵션) grep 위반 검출 자동화 — pre-commit 훅 | 메인테이너 | v0.3 | follow-up |

## Consequences

**Pros**
- 새 엔티티 들어왔을 때 5단 절차가 *재현 가능* — Model 누락 / Migration 빠짐 / Schema-Repository 어긋남 같은 흔한 실수 grep 으로 사전 검출.
- `api-design` (엔드포인트) ↔ `entity-add` (엔티티) 의 *짝* 명시 — 새 도메인 추가 시 호출 순서 (entity → endpoint) 가 자연스러움.
- Pydantic 패턴 박제로 `MissingGreenlet` 함정 (`refresh=False`) 사전 회피 — wiki-09 의 *근거* 와 정합.

**Cons**
- 5단 절차가 *FastAPI + SQLAlchemy + Alembic + Pydantic* 스택 가정 — 다른 스택 (Django ORM / Spring JPA / TypeORM) 은 fallback 으로만 cover.
- Migration 은 별 SKILL (adr-0008) 이라 *연쇄 호출* 필요 — entity-add 안에서 alembic-migration 호출 흐름이 끊기면 사용자 혼란.

**Follow-ups**
- [ ] grep 위반 검출 자동화 — pre-commit hook
- [ ] 관계 (1:N / N:N / 자기 참조) 가 있는 엔티티 패턴 별 examples 추가
- [ ] 다른 ORM 스택 (Django / TypeORM) ADR 분기 (사용 사례 누적 시)

## Notes

_(시간순 append)_

- 2026-05-03 — proposed. wiki-07 → backend role 매핑. 자매 ADR: 0003 (api-design) / 0004 (tdd) / 0005 (refactor) / 0008 (alembic) / 0009 (transaction).
- 2026-05-03: applied to plugin `base` role `backend` (content/harness/plugins/base/role-templates/backend/)
