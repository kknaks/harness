# Example: DB Transaction — fallback (no reference)

> reference 부재 → role-generic fallback case. `sample-with-reference.md` 와 짝.
> 본 자산은 *reference lookup* 이라 sample 도 *디버깅 시나리오* 형태.

## 트리거

```
/db-transaction refresh
```

(상황: `MissingGreenlet` 예외가 user update API 에서 발생, 디버깅 중)

## reference 로드 결과

```
backend.md                  : 없음
<middleware-file>           : 자동 탐색
  - 발견: app/main.py 의 SQLAlchemyMiddleware
BaseRepository.update       : 자동 탐색
  - 발견: app/repositories/base.py — `refresh=True` 디폴트 확인
→ fallback 작동 + 사용자 확인 필요
  ✓ 사용자 확인: SQLAlchemy 2.0 async + Pydantic v2 + 미들웨어 트랜잭션
```

## 출력

````markdown
## DB Transaction Lookup — `MissingGreenlet` 디버깅

### 에러
```
sqlalchemy.exc.MissingGreenlet: greenlet_spawn has not been called;
can't call await_only() here. Was IO attempted in an unexpected place?
```

### lookup 결과

#### 원인 (rules.md §refresh=False 함정)
1. `BaseRepository.update(user, **patch_data)` 호출 — `refresh=True` 디폴트
2. `session.refresh(user)` 가 호출됨 → eager-loaded 관계 (`user.assignments`) 가 expire
3. 이후 `UserResponse.model_validate(user)` 가 `assignments` 필드 직렬화 시도
4. SQLAlchemy 가 lazy load 시도 → async session 의 greenlet 컨텍스트 밖 → `MissingGreenlet`

### 수정

```python
# Before
patch = body.model_dump(exclude_unset=True, exclude_none=True)
await self.repo.update(user, **patch)               # ← refresh=True (디폴트)
return UserResponse.model_validate(user)            # ← MissingGreenlet 발생

# After
patch = body.model_dump(exclude_unset=True, exclude_none=True)
patch.setdefault('updated_at', datetime.now(UTC))   # ← func.now() 함정 회피
await self.repo.update(user, **patch, refresh=False)  # ← refresh 끔
return UserResponse.model_validate(user)            # OK
```

### 검증
- 회귀 테스트 — `test_user_update` Green
- grep 자가 검증:
  ```bash
  grep -rn "self\.repo\.update.*\)" app/services/  # refresh=False 누락 검출
  ```

### 다음 단계
1. 다른 update 호출처도 동일 패턴 점검 (특히 eager-loaded 관계 가진 객체)
2. `refactor-layered` SKILL 의 grep 룰에 `refresh=False` 누락 패턴 추가 검토 (메인테이너 follow-up)

### 참고
- 본 reference 의 §refresh=False 함정 + §commit/flush/rollback 책임 분리 표
- 자매 SKILL: `entity-add` §3 (Pydantic 부분 업데이트) — 같은 패턴 박혀 있음
````

## fallback 의 한계

reference 가 있었다면:
- `<middleware-file>` 위치 자동 (NEXUS 면 `server/app/main.py` 또는 `core/middleware.py`)
- `BaseRepository.update` 디폴트 자동 인식
- grep 룰 자동 출력 (`db.commit()` 검출 명령)

→ 사용처가 reference 박으면 다음 호출부터 자동 로드.
