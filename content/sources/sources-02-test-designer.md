---
id: sources-02
title: Test Designer
type: sources
status: promoted
sources:
  - "[[test-designer]]"
tags: [sources]
categories: [test-design, tdd]
aliases: []
---

# Test Designer

> 1차 가공 = 원본 박제. 이후 불변. 원본의 정체(이름·목적)를 명확히 한 채 보존한다.

## 정체 (Identification)

**원본**: `content/inbox/test-designer`

**무엇인가 (한 줄)**:

NEXUS 백엔드 프로젝트의 *테스트 설계 SKILL* — 기획서를 입력으로 받아 **개발자 의도**를 담은 테스트 스켈레톤(클래스 docstring 기획서 / 메서드 docstring Given-When-Then / 코드 G-W-T 주석)을 산출하는 사내 `/test-design` 슬래시 명령. Mother 패턴(Test Data Builder)과 시나리오 4유형(Happy / Error / 비즈니스 규칙 / 상태 전이) 분류, 표준 출력 리포트 포맷이 박혀 있음.

**왜 보존하는가**:

wiki 단계에서 **공용 골격 (project-agnostic)** 과 **프로젝트 의존 부분** 두 층으로 분리할 1차 자산:
- 공용 골격 후보 — "테스트 = 실행 가능한 문서" 원칙, 3계층 docstring 구조(클래스=기획서 / 메서드=상황·동작·결과 + G-W-T / 코드=`# Given/When/Then` 주석), Test Data Builder(Mother) 패턴, 시나리오 4유형 분류, 테스트 설계 리포트 출력 포맷.
- NEXUS 의존 — `packages/admin-api/tests/mothers/` 디렉토리 위치, `AdminApiClient`/`admin_api_client` fixture 명, 도메인(branch/manager/customer/reservation/...) 어휘, `BRANCH_NAME_DUPLICATE` 같은 에러 코드 컨벤션, HQ vs 지점 권한 분기.

`sources-01-code-review` 와 함께 **개발 라이프사이클의 다른 phase** (리뷰는 사후, 테스트 설계는 사전)를 다룸 → 별도 wiki 노드로 분리 자연스러움. 이후 같은 주제 SKILL(다른 회사·언어 테스트 설계 SKILL) 들이 모이면 `wiki-NN-test-design-pattern` 하나로 합성 → ADR(plugin 매핑 결정) 진행.

## 본문 (raw 인용)


### SKILL.md

~~~markdown
---
name: test-designer
description: |
  테스트 설계 및 스켈레톤 생성. 기획서를 기반으로 개발자 의도가 담긴 테스트를 설계합니다.
  사용 시점: /test-design 명령 호출 시, 새 기능 개발 전 테스트 설계 시
---

# Test Designer Skill

테스트에 개발자 의도를 심어 팀원들에게 비즈니스 규칙을 전달합니다.

## 사용법

```
/test-design                          # 대화형 기획서 입력
/test-design docs/v1/spec.md          # 기획서 파일 기반
/test-design {domain}                 # 기존 도메인 테스트 개선
```

---

## 핵심 원칙: 의도 표현

> 테스트는 **실행 가능한 문서**입니다.
> 코드가 "무엇을 하는지"가 아니라 "왜 그래야 하는지"를 담아야 합니다.

### 나쁜 예 vs 좋은 예

```python
# ❌ 나쁜 예: 무엇만 검증
async def test_create_branch(client):
    response = await client.post("/branches", json={"name": "강남점"})
    assert response.status_code == 201

# ✅ 좋은 예: 왜를 담은 테스트
async def test_creates_branch_with_auto_generated_slug(client):
    """지점 생성 시 slug 자동 생성

    상황: 관리자가 지점명만 입력하여 새 지점 등록
    시스템 동작: 지점명을 기반으로 URL-safe slug 자동 생성
    결과: 201 반환, slug는 한글을 romanize한 형태

    Given: 유효한 지점명 "강남점"
    When: 지점 생성 API 호출
    Then: slug가 "gangnam-jeom" 형태로 자동 생성
    """
    # Given
    branch_data = {"name": "강남점"}

    # When
    response = await client.post("/api/v1/branches", json=branch_data)

    # Then
    assert response.status_code == 201
    data = response.json()["data"]
    assert data["slug"].startswith("gangnam")  # romanized slug
```

---

## 표준 테스트 구조

### 1. 클래스 Docstring (기획서)

```python
class TestCreateBranch:
    """POST /api/v1/branches - 지점 생성

    기획 요구사항:
    ============
    1. 목적
       - 본사 관리자가 새 지점을 시스템에 등록
       - 각 지점은 고유 slug로 URL 식별

    2. 입력
       - Body: name (필수), address, phone (선택)

    3. 응답 데이터
       - branchId: 생성된 지점 ID
       - name: 지점명
       - slug: 자동 생성된 URL slug

    4. 에러 케이스
       - 지점명 중복: 409 CONFLICT
       - 지점명 50자 초과: 422 UNPROCESSABLE_ENTITY

    5. 비즈니스 규칙
       - 본사(HQ) 계정만 생성 가능
       - slug는 지점명 romanize + 숫자 suffix로 고유성 보장
       - 생성 시 기본 상태는 active

    6. 처리 흐름
       1) Router: RequestContext에서 is_hq 확인
       2) BranchService.create() 호출
       3) BranchValidator - 지점명 중복 검증
       4) BranchRepository.create() - slug 자동 생성
       5) BranchCreateResponse 반환
    """
```

### 2. 메서드 Docstring (Given-When-Then)

```python
async def test_rejects_duplicate_branch_name(
    self,
    admin_api_client: AdminApiClient,
    branch_mother: BranchMother,
):
    """지점명 중복 시 409 반환

    상황: 이미 "강남점"이 존재하는 상태에서 동일 이름으로 생성 시도
    시스템 동작: Validator가 중복 검증 후 예외 발생
    결과: 409 CONFLICT, 에러 메시지에 중복 지점명 포함

    Given: "강남점" 지점이 이미 존재
    When: 동일한 이름 "강남점"으로 생성 API 호출
    Then: 409 반환, 에러 코드 BRANCH_NAME_DUPLICATE

    검증 사항:
    - 상태 코드: 409
    - 에러 코드: BRANCH_NAME_DUPLICATE
    - 기존 지점은 변경 없음
    """
```

### 3. 코드 구조 (Given-When-Then 주석)

```python
async def test_scenario(self, ...):
    """Docstring..."""

    # Given - 테스트 전제 조건
    existing_branch = await branch_mother.create(name="강남점")

    # When - 테스트 대상 동작
    response = await admin_api_client.branches.create(
        name="강남점"  # 중복 이름
    )

    # Then - 결과 검증
    assert response.status_code == 409
    error = response.json()
    assert error["code"] == "BRANCH_NAME_DUPLICATE"
    assert "강남점" in error["message"]
```

---

## Mother 객체 활용

### NEXUS Mother 클래스

```
packages/admin-api/tests/mothers/
├── branch_new.py           # BranchNewMother
├── manager.py              # ManagerMother
├── customer.py             # CustomerMother
├── reservation.py          # ReservationMother
├── category.py             # CategoryMother
├── procedure_product.py    # ProcedureProductMother
└── ...
```

### Mother 사용 패턴

```python
async def test_example(
    self,
    admin_api_client: AdminApiClient,
    branch_mother: BranchNewMother,
    manager_mother: ManagerMother,
):
    # Given - Mother로 테스트 데이터 준비
    branch = await branch_mother.create(name="테스트지점")
    manager = await manager_mother.create(
        branch_id=branch.id,
        login_id="test_manager",
    )

    # When - API 호출
    response = await admin_api_client.managers.get(manager.id)

    # Then - 검증
    assert response.status_code == 200
```

---

## 테스트 시나리오 유형

### 1. 성공 케이스 (Happy Path)

```python
async def test_creates_resource_successfully(self):
    """정상 생성

    Given: 유효한 입력 데이터
    When: 생성 API 호출
    Then: 201 반환, 리소스 생성 확인
    """
```

### 2. 에러 케이스 (Edge Cases)

```python
async def test_rejects_invalid_input(self):
    """잘못된 입력 거부

    Given: 필수 필드 누락 / 형식 오류
    When: 생성 API 호출
    Then: 422 반환, 검증 에러 상세
    """

async def test_returns_404_for_nonexistent_resource(self):
    """존재하지 않는 리소스 조회 시 404

    Given: 존재하지 않는 ID
    When: 조회 API 호출
    Then: 404 반환
    """

async def test_prevents_unauthorized_access(self):
    """권한 없는 접근 차단

    Given: 지점 관리자 계정 (HQ 아님)
    When: HQ 전용 API 호출
    Then: 403 반환
    """
```

### 3. 비즈니스 규칙 검증

```python
async def test_enforces_unique_constraint(self):
    """고유성 제약 검증

    Given: 동일 키를 가진 리소스가 이미 존재
    When: 같은 키로 생성 시도
    Then: 409 반환
    """

async def test_cascades_soft_delete(self):
    """연관 데이터 soft delete 연쇄

    Given: 상위 엔티티와 연관 하위 엔티티들
    When: 상위 엔티티 soft delete
    Then: 하위 엔티티도 함께 soft delete
    """
```

### 4. 상태 전이 검증

```python
async def test_transitions_status_correctly(self):
    """상태 전이 규칙 검증

    Given: PENDING 상태의 예약
    When: confirm API 호출
    Then: CONFIRMED 상태로 전이, 전이 시간 기록
    """
```

---

## 출력 형식

설계 완료 후 다음 형식으로 출력:

```markdown
## 테스트 설계 리포트

### 대상
- 도메인: {domain}
- API: {HTTP_METHOD} {endpoint}
- 기획서: {기획서 경로 또는 요약}

### 테스트 클래스 구조

```python
class Test{Action}{Domain}:
    """HTTP_METHOD /endpoint - 설명

    기획 요구사항:
    ============
    1. 목적
    2. 입력
    3. 응답 데이터
    4. 에러 케이스
    5. 비즈니스 규칙
    6. 처리 흐름
    """
```

### 테스트 시나리오 (N개)

| # | 시나리오 | 유형 | Given | When | Then |
|---|---------|------|-------|------|------|
| 1 | 정상 생성 | Happy | 유효한 입력 | POST 호출 | 201 |
| 2 | 중복 거부 | Error | 기존 존재 | POST 호출 | 409 |
| 3 | ... | ... | ... | ... | ... |

### 생성할 파일

- `tests/apis/v1/test_{domain}.py`
  - `Test{Action}{Domain}` 클래스
  - {N}개 테스트 메서드

### 필요한 Mother/Fixture

- `{domain}_mother` - {용도}
- `admin_api_client` - API 호출

---

### 다음 단계

`/test-implement` 명령으로 TDD 구현을 진행하세요.
```

---

## 관련 문서

- `docs/v1/spec.md` - 기능 명세
- `CLAUDE.md` - 프로젝트 가이드라인
- `packages/admin-api/tests/` - 기존 테스트 참고

~~~
