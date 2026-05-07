# Alembic Migration Rules

> 스킬이 강제하는 룰셋·정책·금지 사항. SKILL.md (사용자 시점 진입점) 가 trigger 시 로드 → 본 rules.md 는 실제 룰 적용 시점에 지연 로드 ([[adr-0007-skill-authoring-rules]] §1).

## 명령어 3종

| 명령 | 역할 | 호출 시점 |
|------|------|----------|
| `revision --autogenerate -m "<msg>"` | Model ↔ DB 차이로 revision 생성 | Model 변경 후 |
| `upgrade head` | 미적용 revision 전부 적용 | 로컬 / CI / 배포 |
| `history` | revision 체인 확인 | conflict 의심 시 / 디버깅 |

NEXUS prefix: `docker compose exec server uv run python -m alembic <cmd>` (`uv run alembic` 은 sys.path 문제로 ModuleNotFoundError).

## autogenerate 한계 6종 (수동 보완 필수)

| 영역 | 못 잡는 것 | 보완 |
|------|----------|------|
| 인덱스 | `ix_*`, UNIQUE 변경 | `op.create_index` / `op.drop_index` 수동 |
| FK | ON DELETE / ON UPDATE 액션 변경 | `op.create_foreign_key` 수동 |
| Default | `server_default` 변경 / 추가 | `op.alter_column(server_default=...)` 수동 |
| 컬럼 reorder | Postgres 는 reorder 불가 | drop + add 로 풀어 작성 |
| VARCHAR | 길이 변경 | `op.alter_column(type_=String(N))` 수동 |
| 제약 | CHECK constraint | `op.create_check_constraint` 수동 |

**룰**: revision 생성 후 *반드시* 파일 열어 검토. autogenerate 결과 = 초안.

## forward-only 정책

| 상황 | 동작 |
|------|------|
| revision 작성 | `def downgrade()` 함수는 *작성* (개발용). 단 prod 호출 X |
| 잘못된 revision 발견 | 새 revision 으로 *보정* (drop / 재추가). downgrade 호출 X |
| 로컬 / 테스트 | downgrade 사용 가능 (개발 편의) |

**근거** — prod 무중단 배포의 호환성 매트릭스:

| 상태 | 결과 |
|------|------|
| 구 코드 + 신 스키마 | OK (forward-compatible 스키마) |
| 신 코드 + 구 스키마 | **깨짐** (downgrade 가 만드는 상태) |

→ downgrade = 항상 후자 → prod 금지.

## Conflict 해소 (동시 PR 두 head)

```bash
git pull origin main          # 두 head 동기화
alembic heads                 # head 가 둘인지 확인
alembic merge -m "merge X and Y" <head1> <head2>
git add alembic/versions/<merge>.py
git commit && git push
```

merge revision 은 `op.*` 호출 없이 down_revision 만 둘로 가짐. 실제 DDL 은 양쪽 head 가 이미 가지고 있음.

## 1 변경 = 1 revision (분할 룰)

- 한 PR 안에 여러 스키마 변경이 있어도 *논리 단위로 분할* 가능
- *Model 1 변경 ↔ Revision 1 개* 가 원칙
- 큰 마이그레이션 (다수 테이블) 은 revision 단위로 쪼개 *부분 실패 시 영향 범위* 축소

## DDL 트랜잭션

Alembic revision 1 개 = 1 트랜잭션 (Postgres DDL 트랜잭션 지원). `op.*` 호출 안에서 `commit` X — Alembic runner 가 revision 끝에 commit / 실패 시 rollback. 자세한 근거는 `db-transaction` reference §DDL.

## Don't

- **revision 생성 후 검토 없이 commit** — autogenerate 한계 6종 하나라도 못 잡음
- **prod 에서 `alembic downgrade`** — forward-only 정책 위반
- **revision 안에서 `db.commit()`** — Alembic runner 가 다룸
- **Model 누락 + revision 만 push** — ORM ↔ DB 동기화 깨짐
- **너무 큰 revision (10+ 테이블)** — 부분 실패 시 디버깅 부담 → 분할
- **autogenerate 결과 그대로 prod 적용** — 항상 검토 거치기
