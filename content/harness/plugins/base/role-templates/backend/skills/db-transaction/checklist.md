# DB Transaction Checklist (Reference Lookup)

> reference 자산 — *작업 절차* 가 아니라 *lookup 의사결정 트리*. 본질·룰은 `rules.md` SSOT.
>
> 자매 SKILL (entity-add / alembic-migration / refactor-layered) 가 본 reference 를 호출할 때 어느 §rules 섹션을 봐야 하는지 루팅.

## (시나리오 1) `MissingGreenlet` 디버깅

- [ ] 에러 메시지 확인 — `MissingGreenlet: greenlet_spawn has not been called`
- [ ] **rules.md §`refresh=False` 함정** 으로 이동
- [ ] update 호출처에서 eager-loaded 관계 확인 (`selectinload` / `joinedload`)
- [ ] `refresh=False` 추가 + `func.now()` → `datetime.now(UTC)` 변경
- [ ] 회귀 테스트 통과 확인

## (시나리오 2) Service 가 commit 해도 되는지 의문

- [ ] **rules.md §commit/flush/rollback 책임 분리** 으로 이동
- [ ] *왜 안 되는지* 표 + Service A → Service B 부분 실패 시나리오 읽기
- [ ] grep 로 자가 검증 (`grep -nE "db\.commit\(\)" services/`)
- [ ] commit 발견 시 `flush()` 로 변경 + 미들웨어가 commit 하는지 확인

## (시나리오 3) 격리 수준 결정 — REPEATABLE READ 필요한가

- [ ] **rules.md §격리 수준** 으로 이동
- [ ] 사용 사례 매핑:
  - 단순 조회 / CRUD → READ COMMITTED (디폴트, 그대로)
  - 같은 트랜잭션 다회 read 일관성 (집계 / 잔액) → REPEATABLE READ
  - SERIALIZABLE → 회피 (직렬화 실패 retry 부담)
- [ ] 격리 강화 시 *해당 Service 메서드 안에서만* `SET TRANSACTION ISOLATION LEVEL ...` 적용

## (시나리오 4) 부분 실패를 무시하고 나머지 commit 하고 싶음

- [ ] **rules.md §savepoint** 으로 이동
- [ ] `async with db.begin_nested():` 패턴 적용
- [ ] 예외 처리 — 어떤 예외만 rollback 시킬지 명확히
- [ ] 바깥 트랜잭션은 살아있음을 테스트로 검증

## (시나리오 5) Alembic revision 안에서 commit / rollback 처리

- [ ] **rules.md §DDL 트랜잭션** 으로 이동
- [ ] `op.*` 호출 안에서 `commit()` 호출 안 함을 확인
- [ ] `alembic-migration` SKILL §forward-only 와 정합성 점검

## (시나리오 6) 자매 SKILL 본문에서 reference 1줄 인용

- [ ] entity-add §3 (Pydantic 부분 업데이트) — `refresh=False` 1줄 link
- [ ] alembic-migration §revision (DDL 트랜잭션) — §DDL 1줄 link
- [ ] refactor-layered §grep 룰 — §commit 책임 분리 1줄 link
- [ ] 인용은 *짧게* — 전체 reference 복사 X
