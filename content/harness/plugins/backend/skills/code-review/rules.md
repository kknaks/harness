# Code Review Rules

> 스킬이 강제하는 룰셋. SKILL.md (사용자 시점 진입점) 가 trigger 시 로드 → 본 rules.md 는 실제 리뷰 수행 시 지연 로드 ([[adr-0007-skill-authoring-rules]] §1).

## 4단계 리뷰 프로세스

| Phase | 시간 (가이드) | 본질 |
|-------|---------------|------|
| 1. 맥락 파악 | 1–2분 | 변경 범위·도메인·기존 패턴·변경 목적(새 기능 / 버그 수정 / 리팩토링) 식별 |
| 2. 높은 수준 검토 | 3–5분 | 아키텍처·설계 적절성, 의존성 방향(역방향 없음), reference 컨벤션 위반 여부 |
| 3. 줄 단위 검토 | 5–10분 | 컨벤션 위반·언어 특화 패턴·보안·성능 |
| 4. 요약 | 1–2분 | 심각도 분류·우선순위·**🎉 긍정 피드백 1건 이상 포함** |

순서 강제 — 맥락 없이 줄단위 들어가면 도메인 의도 놓침. 큰 변경에서 phase 1·2 가 가장 큰 가치.

## 변경 규모 임계

**400 줄 초과 변경 → 분할 권장**. 단일 PR 인지 부하 한계. 임계 초과 시:
- 리포트 §맥락 에 "⚠ 분할 권장 (NN 줄)" 명시
- 리뷰는 진행하되 *분할 후 재리뷰* 권고

## 심각도 5분류

| 마커 | 레벨 | 의미 | 예시 |
|------|------|------|------|
| 🔴 | **blocking** | 머지 전 필수 수정 | 보안 취약점·회귀·역방향 의존·타입 오류 |
| 🟡 | **important** | 강력 권장 | Convention 위반·네이밍 불일치·누락된 검증 |
| 🟢 | **nit** | 선택 사항 | 코드 스타일·주석·미사용 import |
| 💡 | **suggestion** | 대안 제시 | 더 나은 패턴·리팩토링 후보 |
| 🎉 | **praise** | 잘된 부분 | 잘 작성된 의도 표현·견고한 설계 — **요약에 1건 이상 필수** |

## 줄 단위 점검 — 언어 무관 / 언어 특화 분리

**언어 무관** (어떤 백엔드든 적용):
- 보안: SQL 인젝션 (raw query·파라미터화 누락), 민감 데이터 노출 (로그·응답 body), 권한 우회
- 성능: N+1 쿼리, 비효율 루프, 미참조 인덱스
- 명명: 도메인 어휘 일관성, 의도 표현 (단순 "data"/"info" 회피)
- 타입 정확성: nullable 처리, 경계값

**언어 특화** (예: Python — 사용처 프로젝트 컨벤션 의존):
- 가변 기본 인자 금지 (`def foo(items=[])` → `=None`)
- bare `except:` 금지 — 구체 exception 만
- 타입 힌트 누락 — `Optional[X]` 대신 `X | None` (PEP 604, Python 3.10+)

## 마크다운 리포트 포맷

```markdown
## Code Review Report

### 맥락
- 대상: {파일 / 도메인}
- 변경 규모: {N} 줄 ({적정 / ⚠ 분할 권장})
- 변경 유형: {새 기능 / 버그 수정 / 리팩토링}
- 컨벤션 reference: {로드된 docs/common/*.md 목록 또는 "fallback (role-generic)"}

### 요약
- 🔴 Blocking: {N}개
- 🟡 Important: {N}개
- 🟢 Nit: {N}개
- 💡 Suggestion: {N}개

---

### 🔴 Blocking Issues

#### [B-001] {제목}
- **파일**: `path:line`
- **문제**: {설명}
- **Convention**: {위반한 규칙} (`docs/{path}.md` 또는 "role-generic")
- **해결방안**:
  \```python
  # Before
  ...
  # After
  ...
  \```

### 🟡 Important Issues
... (동일 포맷, 이슈 ID `I-NNN`)

### 🟢 Nits
... (이슈 ID `N-NNN`)

### 💡 Suggestions
... (이슈 ID `S-NNN`)

### 🎉 잘된 점
- {긍정 피드백 1}
- {긍정 피드백 2}

### 다음 단계
{우선순위 가이드 또는 후속 작업}
```

**필수 요소** (재현 가능성의 핵심):
- 이슈 ID 부여 (`B-NNN` / `I-NNN` / `N-NNN` / `S-NNN`)
- Convention 출처 명시 (`docs/common/...md` 또는 `role-generic`)
- Before / After 코드 블록 (단순 지적 X)
- 🎉 praise 1건 이상

## reference 로드 모델

SKILL trigger 시 사용처 프로젝트 컨벤션 문서를 우선 로드:

| 우선순위 | 경로 | 책임 |
|---------|------|------|
| 1 | `docs/common/*.md` | 도메인·아키텍처 컨벤션 (예: `layer-objects.md`·`layer-design.md`·`code-convention.md`) |
| 2 | `CLAUDE.md` | 프로젝트 가이드라인 (Repository 룰·import 컨벤션 등) |
| 3 (fallback) | role-generic | reference 부재 시 — *MVC / 계층화 일반 원칙·역방향 의존 금지·일반 보안/성능* |

**fallback (role-generic)** 의 점검 항목:
- 계층 분리: presentation / application(service) / domain / infrastructure 경계
- 의존 방향: 외층 → 내층 (역방향 X)
- 검증 책임: input validation 은 경계, business rule 은 도메인 / service
- 입출력 분리: 요청·응답 모델 vs 도메인 모델 분리
- 일반 보안: SQL 인젝션·민감 데이터 노출·권한 검증
- 일반 성능: N+1·과도한 직렬화·블로킹 호출

NEXUS 등 특정 컨벤션은 본 SKILL 본문에 박지 않음 — [[adr-0001-code-review-to-backend]] §자산 분리 룰. 사용 사례 누적 시 분기 ADR + 별도 reference 자산.

## Don't

- 🎉 praise 누락 금지 — 부정 일변도 리뷰는 적용률 ↓.
- 이슈 ID 누락 금지 — 후속 추적 불가.
- Before / After 없이 "고쳐주세요" 만 적기 금지.
- 사용자 코드 직접 수정 금지 — 본 SKILL 은 *리포트 산출* 만. 수정은 사용자 손.
- 시크릿 (`.env`·token 파일·`secrets/`) 을 review 대상에 포함 금지.
- 본 SKILL 본문에 NEXUS / Spring 등 특정 컨벤션 박기 금지 ([[adr-0001-code-review-to-backend]] §자산 분리 룰 §금지).
