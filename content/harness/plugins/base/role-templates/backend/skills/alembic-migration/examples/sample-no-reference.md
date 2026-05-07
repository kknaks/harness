# Example: Alembic Migration — fallback (no reference)

> reference 부재 → role-generic fallback case. `sample-with-reference.md` 와 짝.

## 트리거

```
/alembic-migration new "add unique constraint to user.email"
```

## reference 로드 결과

```
backend.md §배포           : 없음
<alembic-dir>              : 자동 탐색
  - 발견: alembic/ + alembic.ini + alembic/env.py
→ fallback 작동 + 사용자 확인 필요
  ✓ 사용자 확인: Alembic + Postgres + forward-only (사내 정책)
```

## 출력

````markdown
## Alembic Migration 작업 보고

### 대상
- 변경: `user.email` UNIQUE constraint 추가
- reference: fallback (role-generic). Alembic 디렉토리 자동 추정 + 사용자 확인.

### Action
1. `alembic revision --autogenerate -m "add unique constraint to user email"` 실행
2. autogenerate 결과 검토:
   - UNIQUE constraint = autogenerate **못 잡음** ⚠ — 인덱스 한계
   - 수동 추가: `op.create_index('uq_user_email', 'user', ['email'], unique=True)`
3. `alembic upgrade head` 통과 (로컬)
4. `alembic downgrade -1` → `upgrade head` 재실행 통과

### 검토 결과 (autogenerate 한계 6종)
- 인덱스: ⚠ 수동 추가 (UNIQUE)
- FK action: N/A
- server_default: N/A
- 컬럼 reorder: N/A
- VARCHAR 길이: N/A
- CHECK constraint: N/A

### revision 파일
```python
# alembic/versions/abc123_add_unique_constraint_to_user_email.py
def upgrade() -> None:
    op.create_index('uq_user_email', 'user', ['email'], unique=True)

def downgrade() -> None:
    op.drop_index('uq_user_email', table_name='user')
```

### Post-flight
- Model 변경 0 (constraint 만 추가) — single commit
- PR: `chore(db): add unique constraint to user.email`

### 주의
- 기존 `user.email` 에 중복 데이터 있으면 `upgrade` 시 fail.
- 사전 확인: `SELECT email, COUNT(*) FROM user GROUP BY email HAVING COUNT(*) > 1`
- 중복 발견 시 별도 데이터 마이그레이션 revision 먼저 (시나리오 3 단독 변경)
````

## fallback 의 한계

reference 가 있었다면:
- `backend.md §배포` 의 GHCR Action 자동 인식 → prod 자동 마이그레이션 안내
- `<alembic-dir>` prefix 자동 (NEXUS 면 `docker compose exec server uv run python -m alembic`)
- forward-only 정책 자동 강제 (사용자 확인 단계 skip)

→ 사용처가 reference 박으면 다음 호출부터 자동 로드.
