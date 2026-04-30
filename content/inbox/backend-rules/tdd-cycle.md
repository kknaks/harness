---
name: tdd-cycle
description: TDD 사이클 (Red→Green→Refactor) 절차를 실행한다
---

# TDD 사이클

## 실행 조건
새 기능 개발 또는 API 구현 시 실행한다.

## 참고 문서
- `plan/design-standards/testing-strategy.md` — 테스트 피라미드, 케이스 생성 절차, 도메인별 핵심 맵
- `plan/api/` — API 상세 설계 10개 파일, ~210 엔드포인트 (테스트 대상)
- `plan/erd/table-design.md` — BaseEntity, Mixin 패턴 (fixture/팩토리 기반)
- `plan/erd/database-rules.md` — 소프트 딜리트, company_id 스코핑, FK 정책 (테스트 시나리오)

## 절차

### 1. Red (테스트 먼저)
- Test 에이전트가 API 스펙 기반으로 테스트 코드 작성
- `plan/api/` 문서를 참고하여 request/response 테스트
- 실행 → **실패 확인** (구현 코드 없으니까)

### 2. Green (최소 구현)
- Backend 에이전트가 테스트 통과하는 최소한의 코드 작성
- 모델(`plan/erd/table-design.md` BaseEntity 패턴), 스키마, 라우터, 서비스 순서로 구현
- 실행 → **통과 확인**

### 3. Refactor (정리)
- 코드 정리 (중복 제거, 네이밍 개선)
- 테스트는 계속 통과 상태 유지
- 커밋

### 4. 반복
- 다음 기능으로 1~3 반복

## 예시 플로우

```
1. Test: test_create_issue_returns_201() 작성 → 실패
2. Backend: POST /issues 라우터 + 서비스 구현 → 통과
3. Refactor: 스키마 정리, 에러 핸들링 추가 → 통과 유지
4. Test: test_create_issue_without_title_returns_422() 작성 → 실패
5. Backend: 밸리데이션 추가 → 통과
6. 커밋
```
