# Example: DB Transaction — NEXUS Backend (reference 로드)

> NEXUS reference 모두 로드한 case. savepoint 사용 시나리오 demo.

## 트리거

```
/db-transaction savepoint
```

(상황: 배치 import 작업 — 일부 row 가 invalid 해도 *나머지는 commit* 필요)

## reference 로드 결과

```
backend.md                          : 로드 (4계층 / Service flush / 미들웨어 commit)
<middleware-file>                   : 명시 — server/app/main.py SQLAlchemyMiddleware
BaseRepository.update               : 명시 — server/app/repositories/base.py (refresh=True 디폴트)
grep 룰                             : 로드 (refactor-layered §grep 와 정합)
→ 4/4 로드. 충돌 없음.
```

## 출력

````markdown
## DB Transaction Lookup — savepoint 패턴

### 사용 사례
배치 import — CSV 100 row 처리, 일부 row 가 invalid 해도 *나머지 99 row 는 commit*.

### lookup 결과

#### 패턴 (rules.md §savepoint)

```python
# server/app/services/import_service.py
class ImportService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.repo = ItemRepository(db)

    async def import_batch(self, rows: list[ImportRow]) -> ImportResult:
        success = 0
        failed: list[tuple[int, str]] = []

        for idx, row in enumerate(rows):
            async with self.db.begin_nested():    # SAVEPOINT 시작
                try:
                    await self.repo.create(row.to_orm())
                    success += 1
                    # 정상 — SAVEPOINT 자동 release
                except IntegrityError as e:
                    failed.append((idx, str(e)))
                    # 자동 ROLLBACK TO SAVEPOINT — 바깥 트랜잭션 살아있음
                except ValidationError as e:
                    failed.append((idx, str(e)))

        # 미들웨어가 요청 끝에서 commit (정상 row 99개)
        return ImportResult(success=success, failed=failed)
```

#### 책임 분리 검증 (rules.md §commit/flush/rollback)
- Service 안에서 `commit()` 호출 X — 미들웨어 책임
- `begin_nested()` = SAVEPOINT (SQL `SAVEPOINT name`) — request 단위 트랜잭션 안의 부분 단위
- Service 가 명시적으로 다루는 건 SAVEPOINT 만 — 외곽 트랜잭션은 미들웨어

#### NEXUS 미들웨어 흐름
```
request 진입
  └─ Depends(get_db) → AsyncSession 생성
      └─ ImportService.import_batch(rows)
          └─ for row in rows:
              └─ db.begin_nested()  → SAVEPOINT
                  └─ repo.create(row)
                  └─ 성공 → SAVEPOINT release / 실패 → ROLLBACK TO SAVEPOINT
  └─ response 반환 직전
      └─ SQLAlchemyMiddleware.commit (정상 row 99개 영속)
```

### 검증
- 회귀 — invalid row 1개 + valid row 99개 fixture 로 테스트
- 결과: success=99, failed=[(idx, msg)] / DB 에 99 row 박힘
- grep 검증:
  ```bash
  grep -nE "db\.commit\(\)" server/app/services/import_service.py   # 0 ✓
  ```

### 격리 수준 결정 (rules.md §격리 수준)
- 배치 import = 단일 트랜잭션, 다회 read 일관성 무관 → **READ COMMITTED 디폴트 그대로**
- 강화 불필요

### 다음 단계
1. `import_service` 의 다른 메서드도 동일 패턴 점검 (예외 핸들링 부재 시 위험)
2. (선택) failed list 가 일정 % 넘으면 *전체 rollback* 하는 가드 추가 — 비즈니스 정책 결정
````

## reference 로드 효과

NEXUS reference 가 있어서:
- 미들웨어 흐름 자동 출력 (`server/app/main.py` SQLAlchemyMiddleware)
- `BaseRepository.update` 디폴트 (refresh=True) 인식 → 본 시나리오엔 무관하지만 일관 적용
- grep 룰 자동 (`refactor-layered §grep` 와 정합)
- 4계층 책임표 자동 인용 (Service flush / 미들웨어 commit)
