---
id: wiki-01
title: Code Review Pattern
type: wiki
status: promoted
sources:
  - "[[sources-01-code-review]]"
related_to:
  - "[[wiki-02-test-design-pattern]]"
tags: [wiki]
categories: [code-review]
aliases: []
---

# Code Review Pattern

> 합성·정리. 비슷한·연관된 sources 를 묶어 다듬은 지식 노드. LLM 이 합성, **인간이 검토**.

## Summary

코드 리뷰는 **단계화된 점검 → 심각도 분류 → 정형 리포트** 세 축으로 구성된다. 어떤 프로젝트라도 (1) 무엇을 어떤 순서로 볼지, (2) 발견을 어떤 등급으로 분류할지, (3) 결과를 어떤 포맷으로 전달할지 정의되어야 리뷰가 일관·재현 가능해진다. 골격(공용)과 컨벤션(프로젝트 의존)을 분리하면 같은 SKILL 을 다른 프로젝트로 이식할 수 있다.

## Synthesis

### 공용 골격 (project-agnostic)

**1) 4단계 리뷰 프로세스**

| Phase | 시간 (가이드) | 본질 |
|-------|---------------|------|
| 1. 맥락 파악 | 1–2분 | 변경 범위·도메인·기존 패턴·변경 목적(새 기능/버그/리팩토링) 식별 |
| 2. 높은 수준 검토 | 3–5분 | 아키텍처·설계 적절성, 의존성 방향(역방향 없음) |
| 3. 줄 단위 검토 | 5–10분 | 컨벤션 위반·언어 특화 패턴·보안/성능 |
| 4. 요약 | 1–2분 | 심각도 분류·우선순위·**긍정 피드백 포함** |

**2) 변경 규모 임계값** — 400 줄 초과 변경은 분할 권장. 단일 PR 인지 부하 한계.

**3) 심각도 5분류**

| 마커 | 레벨 | 의미 |
|------|------|------|
| 🔴 | blocking | 머지 전 필수 수정 |
| 🟡 | important | 강력 권장 |
| 🟢 | nit | 선택 사항 |
| 💡 | suggestion | 대안 제시 |
| 🎉 | praise | 잘된 부분 — 요약에 **반드시 1건 이상 포함** |

**4) 줄 단위 점검 — 언어 무관 / 언어 특화 분리**

- 언어 무관: 보안(SQL 인젝션·민감 데이터 노출), 성능(N+1 등), 명명·타입 정확성
- 언어 특화 (예: Python): 가변 기본 인자 금지, bare `except` 금지, 타입 힌트 누락, `Optional[X]` 대신 `X | None`

**5) 마크다운 리포트 포맷**

```
## Code Review Report
### 맥락         ← 대상·변경 규모·변경 유형
### 요약         ← 심각도별 카운트
### 🔴 Blocking  ← [B-NNN] 제목 / 파일:라인 / 문제 / Convention 출처 / Before-After
### 🟡 Important
### 🟢 Nits
### 🎉 잘된 점
### 다음 단계
```

이슈 ID 부여(B-/I-/N-) + Convention 출처 명시 + Before/After 코드는 reproducibility 의 핵심.

### 프로젝트 의존 슬롯 (예시: NEXUS 백엔드)

같은 골격 위에 *프로젝트별 컨벤션* 만 슬롯에 끼운다 — `sources-01-code-review` 의 NEXUS 사례:

**아키텍처 컨벤션 슬롯** (참조: `docs/common/layer-objects.md`, `docs/common/layer-design.md`)
- Layer Objects 4객체: Request / Command / Result / Response + 변환 메서드 (`from_request`, `to_repo_kwargs`, `from_model`, `from_result`)
- 검증 3계층: L1 Field(형식) / L2 model_validator(필드 간) / L3 Validator(DB 의존, `validate_for_creation` 패턴, 항상 None 반환)
- Router 룰: 파라미터 4개 이하 · 변환+호출만 · `HTTPException` 사용 금지
- Service 룰: Validator → Repository 순서 · try-except 금지(전역 핸들러) · Command → Result
- Repository 룰: `get_by_xxx()` 추가 금지 · BaseRepository 재사용 (`get`, `get_all`, `exists`)

**적용 메커니즘** — Claude Code 사용자 정의 슬래시 명령 `/review` 본문으로 박힘. 트리거 시 컨벤션 문서(`docs/common/*`, `CLAUDE.md`)를 reference 로 로드.

다른 프로젝트는 위 슬롯만 자기 컨벤션으로 교체:
- 프론트엔드 — 컴포넌트 분리·상태 관리·접근성·번들 사이즈 슬롯
- 데이터 파이프라인 — 스키마 호환성·재처리 안전성·관측 슬롯

## References

- `sources-01-code-review` (NEXUS 백엔드 `/review` SKILL 박제 — 이 wiki 의 첫 sources)
- 관련: `wiki-02-test-design-pattern` — 같은 SKILL 시리즈의 *사전 설계* phase. 본 wiki 는 *사후 리뷰* phase.
