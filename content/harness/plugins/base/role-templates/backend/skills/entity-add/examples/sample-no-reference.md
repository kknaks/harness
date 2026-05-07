# Example: Entity Add — fallback (no reference)

> reference 부재 → role-generic fallback case. `sample-with-reference.md` 와 짝.

## 트리거

```
/entity-add product
```

## reference 로드 결과

```
backend.md                  : 없음
plan/erd/table-design.md   : 없음
plan/erd/database-rules.md : 없음
사용처 디렉토리              : 자동 탐색
  - 발견: app/{models,schemas,repositories,services,routers}/  (FastAPI + SQLAlchemy 추정)
  - alembic/versions/                                          (Alembic 추정)
→ fallback 작동 + 사용자 확인 필요
  ✓ 사용자 확인: FastAPI + SQLAlchemy 2.0 async + Alembic + Pydantic v2
```

## 출력

````markdown
## Entity Add 작업 보고

### 대상
- 엔티티: `product`
- reference: fallback (role-generic). 디렉토리 자동 추정 + 사용자 확인.

### 1. Model — `app/models/product.py`
- `class Product(Base)` — id (UUID), name (str, 200), price (Decimal), created_at, updated_at, deleted_at
- BaseEntity 패턴 부재 → 직접 컬럼 박음 (사용자 확인)
- ENUM 미사용 — `category` 는 VARCHAR + Python Enum (`ProductCategory`)
- FK 없음

### 2. Migration — `alembic/versions/`
- `alembic revision --autogenerate -m "add product"` 실행
- autogenerate 한계 검토: 인덱스 / FK / server_default / VARCHAR / CHECK 모두 N/A (단일 테이블 신규)
- `alembic upgrade head` 통과
- Model + revision 같은 commit (`feat(product): add Product model + migration`)

### 3. Schema — `app/schemas/product.py`
- `ProductCreateRequest` — name, price, category (필수)
- `ProductUpdateRequest` — 모두 Optional
- `ProductResponse` — `model_config = ConfigDict(from_attributes=True)`, id + 모든 필드
- ORM import 0 (Pydantic 만)

### 4. Repository — `app/repositories/product_repo.py`
- `class ProductRepository(BaseRepository[Product]): pass` (BaseRepository 부재 → 사용자 확인 후 fallback BaseRepository 패턴 박음)
- 도메인 쿼리 추가: `list_by_category(category: ProductCategory)`
- 비즈니스 룰 0 / `commit()` 0

### 5. Test — `tdd-cycle` 호출
- `/tdd-cycle product` 인계 → Red → Green → Refactor
- 산출: `tests/api/test_product_api.py` (12 tests)
- 회귀: 87/87 pass (baseline 75 + 신규 12)

### 사후 검증
- 흔한 실수 grep 5종: 모두 0 ✓
- `alembic upgrade head` 통과 ✓
- 테스트 87/87 pass ✓

### 다음 단계
1. `/api-design product` — 엔드포인트 단위 설계
2. (선택) plan/erd/full-erd.md 갱신 (사용자 손)
````

## fallback 의 한계

reference 가 있었다면:
- BaseEntity 패턴 자동 적용 (id UUID + timestamps + soft delete 일관성)
- FK ON DELETE 정책 자동 결정 (`database-rules.md §FK 정책` 따라)
- 매핑 테이블 / 멀티테넌시 룰 자동 적용
- 디렉토리 위치 사용자 확인 단계 skip
- 허용 예외 (`seeds/` / `alembic/`) 자동 인식

→ 사용처가 reference 박으면 다음 호출부터 자동 로드.
