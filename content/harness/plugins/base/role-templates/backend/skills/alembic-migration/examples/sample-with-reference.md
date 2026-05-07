# Example: Alembic Migration — NEXUS Backend (reference 로드)

> NEXUS reference 모두 로드한 case. conflict 해소 시나리오 demo.

## 트리거

```
/alembic-migration merge
```

(상황: 동시 PR 두 개 모두 alembic revision 추가했고, 늦게 머지하는 PR 에서 head 가 둘이 됨)

## reference 로드 결과

```
backend.md §배포                 : 로드 (forward-only / GHCR Action / downgrade 금지)
<alembic-dir>                    : 명시 — server/alembic/versions/
명령어 prefix                     : docker compose exec server uv run python -m alembic
GHCR Action                      : 로드 — push 후 prod 자동 마이그레이션
→ 4/4 로드. 충돌 없음.
```

## 출력

````markdown
## Alembic Migration 작업 보고 — Conflict 해소

### 대상
- 변경: alembic head 두 개 → 단일 head 로 merge
- reference: `backend.md §배포`, NEXUS prefix, GHCR Action (4/4)

### 사전 확인
```
$ docker compose exec server uv run python -m alembic heads
abc123 (head)  # PR-A 의 add_product
def456 (head)  # PR-B 의 add_user_email_index
```

### Action
1. `git pull origin main` — main 의 두 head 동기화
2. `docker compose exec server uv run python -m alembic merge -m "merge product and user_email_index" abc123 def456`
3. 생성된 merge revision 검토:
   ```python
   # alembic/versions/789xyz_merge_product_and_user_email_index.py
   revision = '789xyz'
   down_revision = ('abc123', 'def456')   # 둘 다 부모
   branch_labels = None
   depends_on = None

   def upgrade() -> None:
       pass   # 실제 DDL 은 양쪽 head 가 이미 가지고 있음

   def downgrade() -> None:
       pass
   ```
4. `docker compose exec server uv run python -m alembic upgrade head` 통과

### Post-flight
- merge revision 만 추가 commit:
  ```
  git add server/alembic/versions/789xyz_merge_*.py
  git commit -m "chore(db): merge alembic heads (product + user_email_index)"
  git push
  ```
- PR 에 conflict 해소 사유 명시 — "head 두 개 (`abc123` add_product / `def456` add_user_email_index) merge"
- (자동) GHCR Action 이 prod 에서 `alembic upgrade head` 실행 — 두 revision + merge revision 적용 순서 유지

### 검증
- `alembic heads` → 단일 head (`789xyz`) 확인
- `alembic history` → 트리 형태 확인:
  ```
  789xyz (head, merge)
  ├── abc123  (add_product)
  └── def456  (add_user_email_index)
  ```
- 회귀 테스트 통과

### 주의
- merge revision 은 *DDL 0* — 부모 두 head 의 변경을 *합치지 않음*. 단지 history 그래프 정리.
- 만약 두 head 가 *같은 컬럼* 을 다르게 변경했다면 (실제 충돌) — merge 로 해결 안 됨. 둘 중 하나 revert + 새 revision 작성.
````

## reference 로드 효과

NEXUS reference 가 있어서:
- 명령어 prefix 자동 (`docker compose exec server uv run python -m alembic`)
- forward-only 정책 자동 (downgrade 호출 시 차단)
- GHCR Action 흐름 안내 자동 (push 후 prod 마이그레이션 timing)
- `<alembic-dir>` 위치 사용자 확인 단계 skip
