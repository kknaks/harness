# Backend Rules Checklist

> 운영 체크리스트 — *어떤 순서로 무엇을 점검·실행·검증하는가* (SSOT).
> 룰의 본질 (왜 강제되는가) 은 `rules.md` 가 SSOT. 본 checklist 는 *실행 절차* 만 — 룰 본문 중복 박지 않음.
> 운영 점검 항목이 늘어나면 본 파일을, 룰 자체가 늘어나면 `rules.md` 를 갱신.

## Pre-flight (모든 단계 공통)

- [ ] 호출 단계 식별 — `api-design` / `tdd-cycle` / `refactor-layered` 중 하나
- [ ] 사용처 reference 로드 (5 슬롯 — 부재 시 fallback)
- [ ] 도메인 식별 (인자 또는 cwd 컨텍스트)
- [ ] 충돌 점검 — 두 reference 가 같은 항목을 다르게 말하면 우선순위 낮은 번호 적용 + 보고

## Action — 단계 1: api-design

- [ ] 기존 API 문서 확인 — 중복 / 충돌 회피
- [ ] ERD 확인 — 엔티티 관계 / 필드 타입
- [ ] DB 룰 확인 — 네이밍 / FK 정책 / 소프트 딜리트
- [ ] 엔드포인트 정의 (method / path / 설명)
- [ ] Request 스키마 (Pydantic v2)
- [ ] Response 스키마
- [ ] 에러 케이스 (400 / 401 / 403 / 404 / 422)
- [ ] API 도메인 문서 갱신 (사용자 손)

## Action — 단계 2-3: tdd-cycle

### Red
- [ ] 테스트 파일 박기 (test-design SKILL 의 시나리오 표 활용)
- [ ] 실행 → **실패 확인** (구현 0 이라 당연)

### Green
- [ ] Schema 박기 — `*Request` / `*Response` DTO
- [ ] Router 박기 — `response_model=` 강제
- [ ] Service 박기 — 클래스 기반, Repository 조합
- [ ] Repository 박기 — `BaseRepository[Model]` 상속
- [ ] 테스트 실행 → **통과 확인**

## Action — 단계 4: refactor-layered

- [ ] 사전 스캔 (`rules.md` §grep 기반 위반 검출 의 3 명령)
- [ ] Schema 정렬 — Request / Response 분리 / Pydantic v2 변환
- [ ] Service 정렬 — DB 접근 → Repository 위임 / `data: dict` → DTO
- [ ] Repository 정렬 — BaseRepository 재사용 / 도메인 쿼리만 추가
- [ ] Router 정렬 — DB 호출 제거 / `response_model=` 추가 / 헬퍼 함수 → Service 이전
- [ ] grep 위반 0 확인 (재실행)
- [ ] 회귀 테스트 100% pass

## Post-flight

- [ ] 작업 보고 — §대상 (도메인 · 단계 · reference 로드 결과 · 충돌 항목) + §변경 (생성 · 수정 파일) + §검증 (grep 0 + 테스트 통과 카운트)
- [ ] reference 출처 모든 결정에 박혔는지 확인 (파일 + §)
- [ ] 시크릿 마스킹 확인 (`.env` / token 노출 X)
- [ ] (선택) `code-review` SKILL 인계 — 사후 검토
- [ ] (선택) 다음 단계 SKILL 인계 — `api-design` 끝나면 `test-design` 또는 `tdd-cycle`
