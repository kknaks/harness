---
id: adr-0008
title: Alembic Migration To Backend
type: adr
status: proposed
date: 2026-05-03
sources:
  - "[[wiki-08-alembic-migration-pattern]]"
tags: [adr]
categories: [db-design, migration, schema-evolution]
role: backend
related_to:
  - "[[adr-0007-entity-add-to-backend]]"
  - "[[adr-0009-db-transaction-to-backend]]"
aliases: []
---

# Alembic Migration To Backend

## Context

승격 원본: `content/wiki/wiki-08-alembic-migration-pattern.md` (sources-05 의 Alembic 운영 부분 합성). wiki 두 층 — 공용 골격 (명령어 3종 + autogenerate 한계 6종 + downgrade 금지 정책 + conflict 해소 + 1 변경 1 revision 룰) + NEXUS 슬롯 (`server/alembic/versions/` 위치 + `python -m alembic` 호출 prefix + GHCR Action prod 절차).

자매 SKILL: `entity-add` (adr-0007) = 2단계 Migration *호출처* — 본 SKILL 은 *Migration 자체* 의 절차. 호출 관계라 1 SKILL 통합 후보였지만 분리 (이유는 §Alternatives). `db-transaction` (adr-0009) = DDL 트랜잭션 / migration runner 의 commit 책임 *근거*.

## Decision

backend role plugin 의 신규 SKILL `alembic-migration` 본문에 **공용 골격만** — 명령어 3종 + autogenerate 한계 6종 + downgrade 금지 (forward-only) 근거 (호환성 매트릭스) + conflict 해소 4단계. NEXUS 의 `docker compose exec server uv run python -m alembic` prefix / `alembic/versions/` 위치 / GHCR Action 흐름은 *reference 로드* (`backend.md §배포` / 사용처 `<alembic-dir>`), 부재 시 *role-generic fallback* (Django `migrate` / TypeORM `migration:run` / Liquibase / Flyway 도구 자동 추정).

§부속결정:
- **forward-only 정책은 본문 박제** (단순 룰 X — *근거* 가 호환성 매트릭스라 본문에 명시).
- **autogenerate 한계 6종 체크리스트는 본문** — revision 검토 시 매번 적용.
- **conflict 해소는 본문 4단계** — 동시 PR 흔한 시나리오라 SKILL 핵심 가치.

## Alternatives Considered

| 후보 | 채택 안 한 이유 |
|------|------------------|
| `entity-add` (adr-0007) 의 2단계에 흡수 (1 SKILL 통합) | Migration 은 *엔티티 추가 외에도* 단독 발생 (FK 추가 / 인덱스 변경 / 컬럼 reorder / 데이터 마이그레이션). 트리거가 entity-add 보다 넓음. 별 SKILL 유지 |
| `db-transaction` (adr-0009) 와 합치기 (트랜잭션 reference 통합) | adr-0009 = *reference* (개념 + 룰), 본 SKILL = *절차* (실행 가능 명령). 자산 종류 다름 |
| forward-only 정책을 *별 ADR* 로 분리 | 정책 단독으로는 SKILL 가치 없음 — `alembic-migration` 본문의 *근거* 로 박는 게 자연스러움 |
| autogenerate 사용 금지 (수동 작성만) | 6종 한계 외에는 autogenerate 가 정확 — 금지 시 메인테이너 부담만 늘어남 |
| conflict 해소를 git skill 에 흡수 | conflict 해소 절차는 *Alembic 특수 명령* (`alembic merge`) 포함 — 일반 git 충돌 해소와 다름. 본 SKILL 안에 박는 게 정합 |

## Implementation Path

| Action | 누가 | 언제 | 의존 / 산출 |
|--------|------|------|--------------|
| `alembic-migration` SKILL 본문 (명령어 3종 + autogenerate 한계 6종 + forward-only + conflict 해소) | 메인테이너 | v0.2+ | wiki-08 → SKILL.md / rules.md |
| forward-only 호환성 매트릭스 박기 (구 코드+신 스키마 OK / 신 코드+구 스키마 깨짐) | 메인테이너 | v0.2+ | SKILL.md §downgrade |
| reference 로드 (`backend.md §배포` / `<alembic-dir>` / GHCR Action) | 메인테이너 | v0.2+ | rules.md |
| role-generic fallback (Django / TypeORM / Liquibase / Flyway 자동 추정) | 메인테이너 | v0.2+ | rules.md §fallback |
| examples 세 개 — 단일 컬럼 추가 / FK 변경 (수동 보완) / conflict merge | 메인테이너 | v0.2+ | examples/ |
| `add-role-skill.sh backend alembic-migration "..."` | 메인테이너 | v0.2+ | role.json |
| `adr-to-harness.sh ... backend` Notes | 메인테이너 | v0.2+ | 본 ADR Notes |
| (옵션) revision 검토 자동화 — autogenerate 결과 6종 한계 항목 grep | 메인테이너 | v0.3 | follow-up |

## Consequences

**Pros**
- autogenerate 한계 6종 체크리스트로 *수동 보완 누락* 사전 검출 (특히 인덱스 / FK action / server_default).
- forward-only 정책 *근거* (호환성 매트릭스) 가 본문에 박혀 있어 — 신규 메인테이너가 "왜 downgrade 금지" 를 묻지 않아도 됨.
- conflict 해소 4단계가 *재현 가능* — 동시 PR 흔한 시나리오에서 메인테이너 일관성 보장.

**Cons**
- Alembic 외 도구 (Django / TypeORM 등) 는 fallback 으로만 cover — 명령어 / 옵션이 도구별 다름.
- forward-only 정책이 *모든 환경* 에 적용되지 않음 — 로컬·테스트는 downgrade 허용, prod 만 금지. 사용자 혼동 여지.

**Follow-ups**
- [ ] revision 검토 자동화 — autogenerate 결과 grep
- [ ] 데이터 마이그레이션 (DDL 외 DML) 패턴 별도 ADR 분기 (사용 사례 누적 시)
- [ ] 다른 도구 (Django migrate / TypeORM) ADR 분기 (사용 사례 누적 시)

## Notes

_(시간순 append)_

- 2026-05-03 — proposed. wiki-08 → backend role 매핑. 자매 ADR: 0007 (entity-add 호출처) / 0009 (DDL 트랜잭션 근거).
- 2026-05-03: applied to plugin `base` role `backend` (content/harness/plugins/base/role-templates/backend/)
