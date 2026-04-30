---
id: wiki-02
title: Test Design Pattern
type: wiki
status: promoted
sources:
  - "[[sources-02-test-designer]]"
related_to:
  - "[[wiki-01-code-review-pattern]]"
tags: [wiki]
categories: [test-design]
aliases: []
---

# Test Design Pattern

> 합성·정리. 비슷한·연관된 sources 를 묶어 다듬은 지식 노드. LLM 이 합성, **인간이 검토**.

## Summary

테스트 설계는 **"테스트 = 실행 가능한 문서"** 원칙 위에 (1) 3계층 docstring 으로 의도 표현, (2) Test Data Builder(Mother) 패턴으로 fixture 가독성 확보, (3) 시나리오 유형 분류로 커버리지 누락 방지, 세 축으로 굳는다. 공용 골격(원칙·구조·유형 분류)과 프로젝트 의존(Mother 위치·API 클라이언트·도메인 어휘)을 분리하면 같은 SKILL 을 다른 프로젝트로 이식할 수 있다.

## Synthesis

### 공용 골격 (project-agnostic)

**1) 의도 표현 원칙** — 테스트는 *무엇을* 검증하는지가 아니라 *왜 그래야 하는지* 를 담는다. 함수명·docstring·assertion 메시지가 모두 비즈니스 규칙의 1차 문서가 되도록 작성.

```python
# ❌ test_create_branch — "무엇만"
# ✅ test_creates_branch_with_auto_generated_slug — "왜·어떻게"
```

**2) 3계층 docstring 구조**

| 계층 | 위치 | 담는 내용 |
|------|------|-----------|
| 클래스 | `class Test{Action}{Domain}` | **기획 요구사항 박제** — 목적 / 입력 / 응답 / 에러 케이스 / 비즈니스 규칙 / 처리 흐름 |
| 메서드 | `async def test_*` docstring | **상황·시스템 동작·결과** + Given-When-Then 시나리오 + 검증 사항 목록 |
| 코드 | `# Given / # When / # Then` 주석 | 본문 3구역 명시적 분할 |

→ 클래스 docstring 만 읽어도 기능 명세가 복원 가능, 메서드 docstring 만 읽어도 시나리오 의도가 전달.

**3) Test Data Builder (Mother) 패턴**

- 도메인별 mother fixture (`<entity>_mother`) — 최소 입력으로 유효한 엔티티 생성, 필드 override 허용
- Given 단계에서 mother 호출 1줄 = 셋업 명세 1줄. 본문은 시나리오에만 집중
- 연관 엔티티(예: branch + manager)도 mother chain 으로 표현

**4) 시나리오 유형 4분류** — 빠짐 없이 커버하기 위한 체크리스트

| 유형 | 본질 | 예시 |
|------|------|------|
| Happy Path | 정상 흐름 1개 이상 | `test_creates_resource_successfully` |
| Edge / Error | 입력 부적합·미존재·권한 | `test_rejects_invalid_input`, `test_returns_404_*`, `test_prevents_unauthorized_*` |
| 비즈니스 규칙 | 도메인 제약 | `test_enforces_unique_constraint`, `test_cascades_soft_delete` |
| 상태 전이 | 상태 머신 규칙 | `test_transitions_status_correctly` |

**5) 테스트 설계 리포트 포맷** — 설계 단계 산출물 (구현 전)

```
## 테스트 설계 리포트
### 대상              ← 도메인·API·기획서 출처
### 테스트 클래스 구조 ← 클래스 docstring 6항목 (기획 요구사항)
### 테스트 시나리오 (N개) ← 표: # / 시나리오 / 유형 / Given / When / Then
### 생성할 파일       ← 파일 경로 + 클래스·메서드 카운트
### 필요한 Mother/Fixture
### 다음 단계        ← 구현 SKILL 으로 인계
```

리포트는 *구현 전 합의* 산출물 — TDD 의 "테스트 먼저" 단계의 명세서 역할.

### 프로젝트 의존 슬롯 (예시: NEXUS 백엔드)

같은 골격 위에 *프로젝트별 인프라 가정*만 슬롯에 끼운다 — `sources-02-test-designer` 의 NEXUS 사례:

**Mother 위치 슬롯**
- `packages/admin-api/tests/mothers/{branch_new,manager,customer,reservation,category,procedure_product,...}.py`
- 각 도메인별 Mother 클래스(`BranchNewMother`, `ManagerMother`, ...)

**API 클라이언트 슬롯**
- `AdminApiClient` (관리자 API), 도메인별 sub-client (`admin_api_client.branches`, `.managers`)
- pytest fixture 명: `admin_api_client`, `<entity>_mother`

**도메인 어휘 슬롯**
- 엔티티: branch / manager / customer / reservation / category / procedure-product / ...
- 권한: HQ(본사) vs 지점 — 다수 시나리오에서 권한 분기 검증
- 에러 코드 컨벤션: `BRANCH_NAME_DUPLICATE` 등 `{DOMAIN}_{REASON}` 대문자 스네이크

다른 프로젝트는 위 슬롯만 자기 인프라로 교체:
- 프론트엔드 — Mother 대신 컴포넌트 fixture·MSW handler / API 클라이언트 대신 testing-library render
- 데이터 파이프라인 — Mother 대신 sample 입력 빌더 / API 클라이언트 대신 파이프라인 invoke

## References

- `sources-02-test-designer` (NEXUS 백엔드 `/test-design` SKILL 박제 — 이 wiki 의 첫 sources)
- 관련: `wiki-01-code-review-pattern` — 같은 SKILL 시리즈의 *사후 리뷰* phase. 본 wiki 는 *사전 설계* phase.
