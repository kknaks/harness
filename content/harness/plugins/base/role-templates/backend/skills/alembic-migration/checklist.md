# Alembic Migration Checklist

> 운영 체크리스트 — *어떤 순서로* (SSOT). 본질·룰은 `rules.md` SSOT.

## (시나리오 1) 새 revision 생성 — Pre-flight

- [ ] revision message 작성 (`add product` / `change user.email unique` 등 — 변경 내용 1줄)
- [ ] 사용처 reference 로드:
  - `backend.md §배포` (forward-only 정책 / GHCR Action)
  - `<alembic-dir>` (`alembic.ini` + `env.py` 위치)
  - 부재 시 → fallback (Alembic 디렉토리 자동 추정 + 사용자 확인)
- [ ] 현재 head 확인 — `alembic heads` (head 가 1개여야 정상, 둘이면 시나리오 4 conflict 해소 먼저)
- [ ] Model 변경 commit 안 한 상태 — Model + revision 같은 commit 으로 묶기 위해

### Action

- [ ] `alembic revision --autogenerate -m "<msg>"` (NEXUS prefix: `docker compose exec server uv run python -m alembic`)
- [ ] **autogenerate 한계 6종 검토** (`rules.md §한계` 참조):
  - [ ] 인덱스 (`ix_*`, UNIQUE) — `op.create_index` 수동
  - [ ] FK ON DELETE / ON UPDATE — `op.create_foreign_key` 수동
  - [ ] `server_default` — `op.alter_column(server_default=...)` 수동
  - [ ] 컬럼 reorder — drop + add 로 풀어 작성
  - [ ] VARCHAR 길이 — `op.alter_column(type_=String(N))` 수동
  - [ ] CHECK constraint — `op.create_check_constraint` 수동
- [ ] `alembic upgrade head` 통과 (로컬)
- [ ] `alembic downgrade -1` 후 `upgrade head` 재실행 통과 (로컬 검증)

### Post-flight

- [ ] revision 파일 + Model 변경을 *같은 commit* 으로 묶기
- [ ] PR 에 revision 라인 명시 (`alembic/versions/{rev}_{slug}.py`)
- [ ] (자동) GHCR Action 이 prod 에서 `alembic upgrade head` 실행 — 로그 확인

## (시나리오 2) revision 잘못 박힘 — 보정

- [ ] **prod 에서는 절대 `alembic downgrade` 호출 X**
- [ ] 새 revision 작성 — 잘못된 변경을 *되돌리는* DDL
- [ ] 시나리오 1 절차 그대로 진행 (새 revision 으로 보정)
- [ ] 잘못된 revision 파일은 *삭제 X* (이미 prod 에 적용된 상태)

## (시나리오 3) 단독 스키마 변경 (FK / 인덱스 / server_default)

- [ ] Model 변경 안 함 — `op.*` 직접 작성
- [ ] `alembic revision -m "<msg>"` (autogenerate 없이 빈 revision)
- [ ] `def upgrade()` 에 `op.*` 수동 작성
- [ ] `def downgrade()` 도 작성 (개발용 — prod 호출 X)
- [ ] 시나리오 1 §Post-flight 진행

## (시나리오 4) Conflict 해소 — head 두 개

### Pre-flight

- [ ] `git pull origin main`
- [ ] `alembic heads` 출력 — head 둘 확인

### Action

- [ ] `alembic merge -m "merge X and Y" <head1> <head2>`
- [ ] 생성된 merge revision 검토 — `op.*` 호출 없이 `down_revision` 만 둘로 가짐
- [ ] `alembic upgrade head` 통과

### Post-flight

- [ ] merge revision 만 추가 commit
- [ ] PR 에 conflict 해소 사유 명시
