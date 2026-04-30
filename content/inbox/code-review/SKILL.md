---
name: code-review
description: |
  NEXUS 프로젝트의 Convention 준수 여부를 검토하고 수정 계획을 수립합니다.
  사용 시점: /review 명령 호출 시, PR 생성 전 코드 품질 검토 시, 새 도메인 구현 후 리뷰 요청 시
---

# Code Review Skill

## 사용법

```
/review                           # git diff 기반 변경 파일
/review path/to/file.py           # 특정 파일
/review {domain}                  # 도메인 전체 (branch, equipment 등)
```

---

## 4단계 리뷰 프로세스

### Phase 1: 맥락 파악 (1-2분)

- [ ] 변경 범위 확인 (**400줄 초과 시 분할 권장**)
- [ ] 관련 도메인 파악
- [ ] 기존 코드 패턴 확인
- [ ] 변경 목적 이해 (새 기능, 버그 수정, 리팩토링)

### Phase 2: 높은 수준 검토 (3-5분)

**아키텍처 & 설계**
- [ ] Layer Objects 패턴 준수 (Request/Command/Result/Response)
- [ ] 검증 책임 분리 (L1/L2/L3)
- [ ] 파일 구조 적절성 (`schemas/`, `service/`, `validators/`)

**의존성 방향**
- [ ] Router → Service → Validator → Repository 순서
- [ ] 역방향 의존성 없음

### Phase 3: 줄 단위 검토 (5-10분)

**Convention 위반**
- [ ] 변환 메서드 사용 (`from_request`, `to_repo_kwargs`, `from_model`, `from_result`)
- [ ] Validator 호출 순서 (Service에서 Repository 전에)
- [ ] Router에서 예외 발생 금지

**Python 특화 패턴**
- [ ] 가변 기본 인자 사용 금지 (`def foo(items=[])` ❌)
- [ ] 과도한 예외 처리 (bare except 금지)
- [ ] 타입 힌트 누락
- [ ] `Optional[X]` 대신 `X | None` 사용

**보안 & 성능**
- [ ] SQL 인젝션 위험 (raw query 사용 시)
- [ ] N+1 쿼리 문제
- [ ] 민감 데이터 노출

### Phase 4: 요약 (1-2분)

- [ ] 심각도별 이슈 분류
- [ ] 수정 우선순위 결정
- [ ] 🎉 긍정적 피드백 포함 (잘된 부분)

---

## 체크리스트

### 1. Layer Objects 패턴 (`docs/common/layer-objects.md`)

**객체 분리**
- [ ] Request/Response는 `APISchema` 상속 (camelCase 자동 변환)
- [ ] Command는 `BaseCommand` 상속
- [ ] Result는 `BaseResult` 상속
- [ ] Response는 `BaseResponse` 상속

**변환 메서드**
- [ ] `Command.from_request(request)` 사용
- [ ] `command.to_repo_kwargs()` 사용
- [ ] `Result.from_model(model)` 사용
- [ ] `Response.from_result(result)` 사용

### 2. 검증 책임 분리 (`docs/common/layer-design.md`)

| 레벨 | 위치 | 검증 내용 |
|------|------|----------|
| L1 | Request (Field) | 형식만 (max_length, pattern) |
| L2 | Command (model_validator) | 필드 간 관계 |
| L3 | Validator | DB 의존 (중복, 존재, 상태) |

**Validator 규칙**
- [ ] `validate_for_creation(command)` 패턴 준수
- [ ] Validator는 항상 `None` 반환 (엔티티 반환 금지)
- [ ] 검증 실패 시 도메인 예외 발생

### 3. Router/Service 규칙

**Router**
- [ ] 파라미터 4개 이하
- [ ] 변환 + 호출만 (비즈니스 로직 없음)
- [ ] `HTTPException` import/사용 금지

**Service**
- [ ] Validator 호출 → Repository 호출 순서
- [ ] try-except 없음 (예외는 전역 핸들러가 처리)
- [ ] Command 입력 → Result 출력

### 4. Repository 규칙 (`CLAUDE.md`)

- [ ] `get_by_xxx()` 메서드 추가 금지
- [ ] BaseRepository 메서드 재사용 (`get()`, `get_all()`, `exists()`)

### 5. 코드 스타일 (`docs/common/code-convention.md`)

- [ ] 절대 경로 import (`from nexus_shared.models...`)
- [ ] 모든 함수에 타입 힌트
- [ ] Public 함수/클래스에 Docstring (Google Style)

---

## 심각도 분류

| 이모지 | 레벨 | 의미 | 예시 |
|--------|------|------|------|
| 🔴 | **blocking** | 필수 수정, 머지 불가 | Validator 미호출, 타입 오류 |
| 🟡 | **important** | 강력 권장 | Convention 위반, 네이밍 불일치 |
| 🟢 | **nit** | 선택 사항 | 코드 스타일, 주석 |
| 💡 | **suggestion** | 대안 제시 | 더 나은 방법 제안 |
| 🎉 | **praise** | 칭찬 | 잘 작성된 코드 |

---

## 출력 형식

```markdown
## Code Review Report

### 맥락
- 대상: {파일/도메인}
- 변경 규모: {N}줄 (적정 / ⚠️ 분할 권장)
- 변경 유형: {새 기능 / 버그 수정 / 리팩토링}

### 요약
- 🔴 Blocking: {N}개
- 🟡 Important: {N}개
- 🟢 Nit: {N}개

---

### 🔴 Blocking Issues

#### [B-001] {제목}
- **파일**: `path:line`
- **문제**: {설명}
- **Convention**: {위반한 규칙} (`docs/xxx.md`)
- **해결방안**:
  ```python
  # Before
  ...
  # After
  ...
  ```

---

### 🟡 Important Issues

#### [I-001] {제목}
- **파일**: `path:line`
- **해결방안**: {설명}

---

### 🟢 Nits

#### [N-001] {제목}
- **파일**: `path:line`
- **제안**: {설명}

---

### 🎉 잘된 점
- {긍정적 피드백 1}
- {긍정적 피드백 2}

---

### 다음 단계
`/analyze` 명령으로 우선순위 분석을 진행하세요.
```

---

## 관련 문서

- `docs/common/layer-objects.md` - Layer Objects 패턴
- `docs/common/layer-design.md` - 계층 구조, Validator, 예외 처리
- `docs/common/code-convention.md` - 코드 스타일
- `CLAUDE.md` - 프로젝트 가이드라인
