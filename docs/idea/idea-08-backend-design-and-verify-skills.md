---
id: idea-08
type: idea
status: rejected
created: 2026-05-02
rejected: 2026-05-02
tags: [idea, rejected]
---

# backend-design-and-verify-skills

> **RETRACTED (2026-05-02)** — 레이어 오인. 플러그인 SKILL 자산은 *콘텐츠 레이어* (`content/inbox` → `sources` → `wiki` → `adr` → `harness`) 소관. 메타 레이어(idea/spec/adr) 는 하네스 시스템 자체 결정용. 또한 토픽 대부분이 이미 진행 중인 `content/inbox/backend-rules/` (sources-03 → wiki-03/04/05) 와 중복.
>
> 후속:
> - 빠진 부분 = **DB 설계 절차** (모델/Alembic/Pydantic/트랜잭션). `content/inbox/db-design/` 으로 raw dump.
> - (옵션) `medi_docs` 정책 매칭 검증은 별도 inbox dump 검토.
>
> 아래 결정 표는 retract 시점 기준 보존 (분석 컨텍스트로 활용 가능).

백엔드 작업 흐름에서 자주 반복되는 두 가지 — **구조 설계** 와 **코드 검증** — 을 스킬로 만든다.

## 시드 (사용자 발화 그대로)

> "백엔드용 구조 설계랑 코드 검증 방법을 스킬화 하고 싶어"

## 두 토픽

1. **구조 설계 스킬** — 새 기능/도메인 들어왔을 때 디렉토리·레이어·모듈 경계·DB 스키마·API 인터페이스 등을 어떻게 설계할지 가이드.
2. **코드 검증 스킬** — 작성된 백엔드 코드가 규칙·정책·테스트 측면에서 올바른지 점검하는 방법.

## 결정 (Q1-Q3 확정)

| # | 항목 | 결론 |
|---|------|------|
| Q1 | 대상 스택 | **Python — FastAPI + Alembic + Pydantic + SQLAlchemy** (사내 표준) |
| Q2 | 구조 설계 스킬 산출물 | **디렉토리 트리 + Alembic 마이그레이션**. (Pydantic schema / SQLAlchemy model / FastAPI router 레이어 포함) |
| Q3 | 코드 검증 스킬 축 | **3축 모두**. (a) 린트, (b) 테스트 — **TDD 위주** (테스트 선행 / 커버리지), (c) 정책 매칭 — `medi_docs` SSOT 비교 |

## 작업 가정 (Q4-Q6, wiki 단계에서 회수 가능)

| # | 항목 | 기본 가정 | 회수 조건 |
|---|------|----------|----------|
| Q4 | 1 스킬 vs 2 스킬 | **2 스킬 분할** — 트리거 시점이 다름 (설계 = 코드 0줄, 검증 = 코드 후). 상위 폴더 하나(`backend/`) 아래 `design/` + `verify/` | wiki 작성 중 책임이 한 스킬로 응집되면 1 스킬로 회수 |
| Q5 | `doc-consult` / `doc-verify` 와 관계 | **축이 다름** — 기존 짝은 *문서 ↔ 정책*, 신규는 *코드 ↔ 정책*. `doc-verify` 의 SSOT 패턴은 재사용 (medi_docs 를 그대로 SSOT 로) | wiki 작성 중 코드 검증 로직 ⊂ doc-verify 라면 doc-verify 일반화로 흡수 |
| Q6 | `code-review` SKILL 과 차별점 | **스택·SSOT 한정** — `code-review` 는 일반 PR 리뷰, 신규 스킬은 *FastAPI/SQLAlchemy 백엔드 한정* + *medi_docs 정책 매칭* 전용. code-review 는 후크하지 않고 별도 스킬 | wiki 작성 중 룰셋이 일반 PR 리뷰와 90% 겹치면 code-review 의 백엔드 프로파일로 흡수 |

## 추가 OQ (wiki 단계에서 결정)

- **OQ7.** medi_docs 어느 부분을 SSOT 로? (전체 / `02_정책서.md` 만 / domain별 매핑?)
- **OQ8.** TDD 검증의 강제 수준 — 테스트 존재만 vs 실제 실행 vs 커버리지 임계?
- **OQ9.** Alembic 마이그레이션 산출 — schema diff 만 vs `alembic revision` 자동 생성?
- **OQ10.** 구조 설계 스킬의 입력 — 자유 텍스트 요구사항 vs Jira 티켓 vs medi_docs 기획서(`planning/NN-slug.md`)?

## 다음 단계

`promote-docs` 로 spec 승격 — Q4 작업 가정대로 **2 spec 분할** 권장:

- `spec-NN-backend-design-skill` — 구조 설계 (디렉토리 + 마이그레이션)
- `spec-NN-backend-verify-skill` — 코드 검증 (린트 + TDD + 정책 매칭)

wiki 단계 진입 시 OQ7-10 + 작업 가정 회수 여부 함께 결정.
