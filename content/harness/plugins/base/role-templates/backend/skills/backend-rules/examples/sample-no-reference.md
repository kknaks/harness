# Example: Backend Rules — Generic Backend (fallback)

> reference 부재 → role-generic fallback 으로 동작한 case sample. `sample-with-reference.md` 와 짝.

## 트리거

```
/backend-rules api-design product
```

## reference 로드 결과

```
plan/api/*.md            : 없음 (사용처가 API 도메인 문서 미보유)
plan/erd/*.md            : 없음
plan/design-standards/   : 없음
plan/refactor/           : 없음
CLAUDE.md                : 없음
→ fallback (role-generic) 작동
  - REST 표준 URL/메서드 컨벤션
  - 4계층 디렉토리 자동 탐색: server/app/{routers,services,repositories,schemas}/
  - 사용자에게 도메인 어휘 주입 요청 → "product (id, sku, name, price), 권한 분기 없음, 멀티테넌시 X"
```

## 출력

````markdown
## Backend Rules 작업 보고

### 대상
- 단계: 1. api-design
- 도메인: `product`
- reference 로드: fallback (role-generic). 도메인 어휘는 사용자 주입.

### API 설계 결과 (api-design 단계)

| Method | Path | 설명 | Response | 에러 |
|--------|------|------|----------|------|
| POST | `/products` | 상품 등록 | 201 + Product | 422 (price ≤ 0) |
| GET | `/products` | 상품 목록 | 200 + Page[Product] | — |
| GET | `/products/{id}` | 상품 단건 | 200 + Product | 404 |
| PATCH | `/products/{id}` | 상품 수정 | 200 + Product | 404, 422 |
| DELETE | `/products/{id}` | 상품 soft delete | 204 | 404 |

### 변경 파일

(이 단계에서 사용자가 생성·수정해야 할 파일 — 사용자 손)
- `<api-docs>/product.md` (신규 — 사용자 디렉토리 미박힘 → 위치 사용자 결정)

### 검증
- 4계층 grep: skip (구현 단계 아님)
- reference 충돌: 없음 (fallback 만 사용)

### 다음 단계
1. (사용자) API 도메인 문서 박기 — fallback 으로는 위치 / 형식 추천만
2. `/test-design product` (자매 SKILL) — 시나리오 합의
3. `/backend-rules tdd-cycle product` Red → 테스트 작성

> ⚠️ fallback 안내: 사용처 프로젝트가 `plan/api/<domain>.md` 패턴을 박으면 다음 호출부터 자동 로드됨. 분기 ADR 도입 시 [[adr-0003-backend-rules-to-backend]] §자산 분리 룰 (b) 참조.
````

## fallback 의 한계

reference 가 있었다면 추가로 잡혔을 가능성:
- 기존 API 와 충돌 검출 (도메인 문서가 있어야 비교 가능)
- DB 컨벤션 (PK 타입 / 소프트 딜리트 / 멀티테넌시 키) — fallback 에선 사용자 주입에 의존
- 4계층 디렉토리 위치 — Spring vs Express vs FastAPI 추정 정확도 ↓
- 코딩 컨벤션 / 에러 핸들링 / 보안 / 테스트 전략 — `plan/design-standards/*.md` 부재 시 일반 원칙으로만

→ 사용처 프로젝트가 reference 박으면 자동 로드. fallback 은 *시작점*, 사용 누적되면 reference 를 박는 게 정답.
