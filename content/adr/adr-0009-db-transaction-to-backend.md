---
id: adr-0009
title: DB Transaction To Backend
type: adr
status: proposed
date: 2026-05-03
sources:
  - "[[wiki-09-db-transaction-reference]]"
tags: [adr]
categories: [db-design, transaction]
role: backend
asset_type: reference
related_to:
  - "[[adr-0005-refactor-layered-to-backend]]"
  - "[[adr-0007-entity-add-to-backend]]"
  - "[[adr-0008-alembic-migration-to-backend]]"
aliases: []
---

# DB Transaction To Backend

## Context

승격 원본: `content/wiki/wiki-09-db-transaction-reference.md` (sources-05 의 트랜잭션 부분 합성). wiki 두 층 — 공용 골격 (ACID + 격리 수준 + commit/flush/rollback 책임 분리 + savepoint + async session 라이프사이클 + `refresh=False` 함정 + DDL 트랜잭션) + NEXUS 슬롯 (`server/app/main.py` 미들웨어 / `core/deps.py` `get_db()` / `BaseRepository.update(refresh=True)` 디폴트 / grep 룰).

**자산 종류가 다름**: 본 자산 = *reference wiki* (개념 + 근거 + 룰), 자매 SKILL 들 (entity-add / alembic-migration) = *절차*. SKILL 들의 본문에 1줄 참조로 인용되는 *근거 reference* 역할.

자매 SKILL: `refactor-layered` (adr-0005) = grep 룰 짝 — 본 reference 가 *왜 그 grep 룰인지* 의 근거 제공. `entity-add` (adr-0007) = Service `flush()` 호출처 — 본 reference 의 책임 분리표 1줄 인용. `alembic-migration` (adr-0008) = DDL 트랜잭션 근거.

## Decision

backend role plugin 의 신규 자산 `db-transaction` 을 **SKILL 이 아닌 reference 문서** (`rules/` 또는 `references/` 디렉토리) 로 박기. 본문에 **공용 골격만** — ACID 표 + 격리 수준 표 + commit/flush/rollback 책임 분리표 + `Service 가 commit 하면 안 되는 이유` + savepoint 패턴 + async session 라이프사이클 + `refresh=False` 함정 (`MissingGreenlet` 의 *왜*) + DDL 트랜잭션. NEXUS 의 미들웨어 위치 / `BaseRepository` 디폴트 / grep 명령은 *reference 로드* (`backend.md` / 사용처 `<middleware-file>`), 부재 시 *role-generic fallback* (Django `atomic` / JPA `@Transactional` / TypeORM `@Transaction` 매핑).

§부속결정:
- **SKILL 이 아닌 reference 자산** — 절차가 아니라 *개념 + 룰* 묶음. 트리거가 *능동적 작업* 아닌 *다른 SKILL 호출 시 lookup*.
- **자매 SKILL 본문에서 1줄 참조** — entity-add / alembic-migration / refactor-layered 의 SKILL.md 가 본 reference 를 link.
- **grep 룰은 refactor-layered (adr-0005) 와 공유** — 본 reference 가 *근거*, refactor-layered 가 *적용*.

## Alternatives Considered

| 후보 | 채택 안 한 이유 |
|------|------------------|
| `db-transaction` 도 SKILL 로 (절차화) | 트랜잭션 작업 = *재현 가능 절차* 가 없음. 다른 SKILL 호출 중 *판단 도구* 로 쓰임. SKILL 부적합 |
| `entity-add` (adr-0007) 안에 흡수 (Service 단계 reference) | entity-add 는 *데이터 단위 5단 절차*, 트랜잭션은 *모든 Service 메서드 공통*. 흡수 시 alembic-migration / refactor-layered 의 참조처가 사라짐 |
| `refactor-layered` (adr-0005) 의 grep 룰 본문에 합치기 | refactor-layered = *4계층 정렬 절차*, 본 reference = *트랜잭션 개념*. 토픽 다름. grep 룰은 *공유*, 근거는 분리 |
| ACID / 격리 수준만 박고 NEXUS 슬롯 (refresh=False / 미들웨어) 분리 | `refresh=False` 함정의 *왜* 가 reference 의 핵심 가치 — 분리 시 사용자 혼동 (SKILL 본문에서 1줄 참조 시 어디 가야 할지 불명) |
| 일반 SQLAlchemy 문서 link 만 두고 본 reference 생략 | 일반 문서는 *FastAPI async + Alembic + Pydantic* 조합 함정 (`MissingGreenlet`) cover 안 함. 사내 reference 가치 명확 |

## Implementation Path

| Action | 누가 | 언제 | 의존 / 산출 |
|--------|------|------|--------------|
| `db-transaction` reference 본문 (ACID + 격리 + 책임 분리 + savepoint + async session + refresh 함정 + DDL) | 메인테이너 | v0.2+ | wiki-09 → references/db-transaction.md |
| 자매 SKILL 본문에 1줄 참조 추가 (entity-add §3 / alembic-migration §revision / refactor-layered §grep 근거) | 메인테이너 | v0.2+ | adr-0007 / 0008 / 0005 SKILL.md 갱신 |
| reference 로드 (`backend.md` / `<middleware-file>` / `BaseRepository.update`) | 메인테이너 | v0.2+ | references/db-transaction.md §NEXUS |
| role-generic fallback (Django `atomic` / JPA / TypeORM 매핑) | 메인테이너 | v0.2+ | references/db-transaction.md §fallback |
| examples — Service flush 패턴 / 미들웨어 commit 패턴 / savepoint 부분 롤백 / refresh=False 사용 | 메인테이너 | v0.2+ | examples/ |
| (옵션) `add-role-reference.sh backend db-transaction "..."` 같은 sh 추가 — reference 자산 등록용 | 메인테이너 | v0.3 | promote-docs 보강 |
| `adr-to-harness.sh ... backend` Notes | 메인테이너 | v0.2+ | 본 ADR Notes |

## Consequences

**Pros**
- `MissingGreenlet` / `commit() 위치 잘못` 같은 *async + ORM* 흔한 함정의 *근거* 가 단일 출처 — 자매 SKILL 들이 1줄 참조로 일관성 확보.
- ACID / 격리 수준이 박혀 있어 — 신규 메인테이너가 *왜 READ COMMITTED 디폴트* / *언제 REPEATABLE READ 필요* 결정 가능.
- 자매 SKILL (entity-add / alembic / refactor-layered) 의 본문 분량 줄임 — *근거* 는 reference 로 위임, *절차* 만 SKILL 본문.

**Cons**
- *reference 자산* 처리가 promote-docs SKILL 에 명시되지 않음 — `add-role-skill.sh` 외 별도 sh 또는 수동 배치 필요. 프로세스 부담.
- SKILL 본문에서 reference 까지 *2 단계 lookup* — 사용자가 즉시 답을 못 얻고 reference 까지 가야 하는 경우 마찰.
- async / sync ORM 차이 (`MissingGreenlet` 은 async 한정) 이 fallback 에서 정확히 매핑 안 됨 — Django sync ORM 사용자에게는 무관.

**Follow-ups**
- [ ] promote-docs SKILL 에 *reference 자산* 처리 절차 추가 (별도 ADR)
- [ ] async / sync ORM 차이를 fallback 에 명시 (Django sync 는 `refresh=False` 함정 N/A)
- [ ] 격리 수준 *런타임 변경* 패턴 examples 추가 (REPEATABLE READ 임시 적용)

## Notes

_(시간순 append)_

- 2026-05-03 — proposed. wiki-09 → backend role reference 매핑. 자매 ADR: 0005 (refactor grep 짝) / 0007 (entity-add 인용처) / 0008 (DDL 트랜잭션 근거).
- 2026-05-03: applied to plugin `base` role `backend` (content/harness/plugins/base/role-templates/backend/)
