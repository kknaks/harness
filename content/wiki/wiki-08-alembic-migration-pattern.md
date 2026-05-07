---
id: wiki-08
title: Alembic Migration Pattern
type: wiki
status: promoted
sources:
  - "[[sources-05-db-design]]"
related_to:
  - "[[wiki-07-entity-add-pattern]]"
  - "[[wiki-09-db-transaction-reference]]"
tags: [wiki]
categories: [db-design, migration, schema-evolution]
aliases: []
---

# Alembic Migration Pattern

> 합성·정리. sources-05 의 Alembic 운영 부분에서 합성. **인간 검토 필요**.

## Summary

스키마 변경 1 단위 = Alembic revision 1 개. autogenerate 사용 + 한계 6종 수동 보완 + downgrade 금지 (forward-only) + 동시 PR conflict 해소. `wiki-07 (entity-add)` 의 2단계 본체 상세 + prod 무중단 배포 정책 박제.

## Synthesis

### 공용 골격 (project-agnostic)

**1) 명령어 3종**

| 명령 | 역할 | 호출 시점 |
|------|------|----------|
| `revision --autogenerate -m "<msg>"` | Model ↔ DB 차이로 revision 생성 | Model 변경 후 |
| `upgrade head` | 미적용 revision 전부 적용 | 로컬 / CI / 배포 |
| `history` | revision 체인 확인 | conflict 의심 시 / 디버깅 |

**2) autogenerate 한계 6종 (수동 보완 필수)**

| 영역 | 못 잡는 것 | 보완 |
|------|----------|------|
| 인덱스 | `ix_*`, UNIQUE 변경 | `op.create_index` / `op.drop_index` 수동 |
| FK | ON DELETE / ON UPDATE 액션 변경 | `op.create_foreign_key` 수동 |
| Default | `server_default` 변경 / 추가 | `op.alter_column(server_default=...)` 수동 |
| 컬럼 reorder | Postgres 는 reorder 불가 | drop + add 로 풀어 작성 |
| VARCHAR | 길이 변경 | `op.alter_column(type_=String(N))` 수동 |
| 제약 | CHECK constraint | `op.create_check_constraint` 수동 |

**룰**: revision 생성 후 *반드시* 파일 열어 검토. autogenerate 결과 = 초안.

**3) downgrade 금지 정책 (forward-only)**

| 상황 | 동작 |
|------|------|
| revision 작성 시 | `def downgrade()` 함수는 *작성* (개발용). 단 prod 호출 X |
| 잘못된 revision 발견 | 새 revision 으로 *보정* (drop / 재추가). downgrade 호출 X |
| 로컬 / 테스트 | downgrade 사용 가능 (개발 편의) |

**근거**: prod 무중단 배포의 호환성 매트릭스.

| 상태 | 결과 |
|------|------|
| 구 코드 + 신 스키마 | OK (forward-compatible 스키마) |
| 신 코드 + 구 스키마 | **깨짐** (downgrade 가 만드는 상태) |

→ downgrade = 항상 후자 → 금지.

**4) Conflict 해소 (동시 PR 두 개 모두 revision 추가했을 때)**

```bash
git pull origin main          # 두 head 동기화
alembic heads                 # head 가 둘인지 확인
alembic merge -m "merge X and Y" <head1> <head2>
git add alembic/versions/<merge>.py
git commit && git push
```

merge revision 은 `op.*` 호출 없이 down_revision 만 둘로 가짐. 실제 DDL 은 양쪽 head 가 이미 가지고 있음.

**5) 1 변경 = 1 revision** (분할 룰)

- 한 PR 안에 여러 스키마 변경이 있어도 *논리 단위로 분할* 가능. 단 *Model 1 변경 ↔ Revision 1 개* 가 원칙.
- 큰 마이그레이션 (다수 테이블) 은 revision 단위로 쪼개 *부분 실패 시 영향 범위* 축소.

### 프로젝트 의존 슬롯 (예시: NEXUS 백엔드)

- **revision 위치**: `server/alembic/versions/`
- **명령어 prefix**: `docker compose exec server uv run python -m alembic ...` (`uv run alembic` 은 sys.path 문제로 ModuleNotFoundError)
- **env.py**: `server/alembic/env.py` — async 엔진, `Base.metadata` 참조
- **정책 출처**: `backend.md §배포` — forward-only / GHCR Action 이 push 후 마이그레이션
- **prod 절차**: GitHub Actions → server pull + `alembic upgrade head` + restart
- **로컬 절차**: `docker compose exec server uv run python -m alembic upgrade head` (시드 전 실행)

다른 도구 매핑 — Django `migrate`, TypeORM `migration:run`, Liquibase `update`, Flyway `migrate`. forward-only 정책은 도구 무관.

## References

- `sources-05-db-design` (Alembic 운영 부분)
- 자매 wiki: `wiki-07-entity-add-pattern` (2단계 Migration 호출처)
- 자매 wiki: `wiki-09-db-transaction-reference` (DDL 트랜잭션 / migration 안 commit)
- ADR 계보: `[[adr-XXXX-alembic-migration-skill]]` (예정)
