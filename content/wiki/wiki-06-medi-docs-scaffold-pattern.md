---
id: wiki-06
title: medi-docs Scaffold Pattern
type: wiki
status: promoted
sources:
  - "[[sources-04-medi-docs-ssot]]"
related_to: []
tags: [wiki, medi-docs, lineage, ssot]
categories: [docs-scaffold]
aliases: [medi-docs-pattern, user-docs-scaffold-pattern]
---

# medi-docs Scaffold Pattern

> 합성·정리. 비슷한·연관된 sources 를 묶어 다듬은 지식 노드. LLM 이 합성, **인간이 검토**.

## Summary

사용자 프로젝트에 정형화된 문서 구조 (9 카테고리 flat + 시점 박제 + lineage 그래프) 를 자동 scaffold 하고, 자동 검증 / 자동 인덱싱 / 명시적 박제 3단을 plugin 자산 (templates + hooks + skill) 묶음으로 입주시키는 패턴. 핵심 가치 = "플러그인 깔면 정형 docs 구조 + 자동 매핑 점검" — 사용자는 문서만 쓰고, scaffold·검증·인덱싱은 plugin 이 처리한다. 골격 (9 카테고리·관계 4종 어휘·planning-root lineage·D4 강제·cut/uninstall 정책) 은 프로젝트 무관, 슬롯 (카테고리 활용 깊이·버전 라벨 컨벤션·도메인 어휘) 은 사용자 자율.

## Synthesis

### 공용 골격 (project-agnostic)

**1) 9 카테고리 flat 구조**

| 카테고리 | 본질 |
|---------|------|
| `planning/` | 기획·요구사항·RFP — *무엇을* (root) |
| `plan/` | 마일스톤·스프린트·일정 — *언제·어떻게* (planning 의 파생 진실) |
| `spec/` | 기술 명세 (API, 컴포넌트, 시스템) |
| `policy/` | 도메인 정책·비즈니스 규칙 |
| `adr/` | 결정 로그 (atomic) |
| `runbook/` | 운영 절차·배포 가이드 |
| `test/` | 테스트 시나리오·회귀 |
| `release-notes/` | 변경 이력 (사용자용) |
| `retrospective/` | 회고·포스트모템 (cross-cutting) |
| `_map.md` | auto — 관계 그래프 + planning-root lineage 트리 |

flat 유지 원칙 — 위계는 디렉토리 깊이가 아니라 frontmatter `sources:` 그래프로 표현. 사이클 매핑: `planning → plan → spec/policy → adr → 구현 → test → release-notes → runbook → retrospective`.

**2) `current/` + `v{label}/` carry-forward 모델**

- `current/` = 살아있는 incremental 작업 상태.
- `v{label}/` = cut 시점 박제 스냅샷 (read-only).
- cut 후 `current/` 그대로 유지 → 누적 작업 자연. `diff -r v1.0/ v1.1/` 로 정책 변화 추적.
- cut 박제 범위 = `current/` 전체 + `_map.md` (관계 그래프 그 시점 동결).

**3) frontmatter 관계 4종 어휘 공유**

medi_docs 는 harness 메타 (`docs/idea/spec/adr`) + harness 콘텐츠 (`content/inbox→...→harness`) 와 **동일한 frontmatter 어휘 + 관계 4종을 공유**한다 (`_map.md` 만 레이어별 분리).

| 관계 | 의미 | medi_docs 내 용도 |
|------|------|-------------------|
| `sources` | 출처·lineage 진실 흐름 | 비-planning 문서 최소 1개 필수 (D4) |
| `related_to` | 동급 횡단 관계 | cross-cutting 참조 |
| `supersedes` | 결정 갈아엎기 | carry-forward 누적 시 *v1.0 잘못된 결정 → v1.1 정정* 명시 |
| `depends_on` | 의존 (구현·작업 순서) | spec/test/runbook 간 의존 그래프 |

**4) planning-root lineage 위계 (SSOT)**

```
planning/                                       (root)
  ├─ policy/*       sources: [[planning/...]]
  └─ plan/*         sources: [[planning/...]]
        ├─ spec/*           sources: [[plan/...]]
        ├─ adr/*            sources: [[spec/...]] 또는 [[plan/...]]
        ├─ test/*           sources: [[spec/...]]
        ├─ runbook/*        sources: [[spec/...]]
        └─ release-notes/*  sources: [[plan/...]]   (cut 시점 산출)

retrospective/*   sources: 다수 cross-cutting (planning/plan/spec 등)
```

진입점 1개 (`planning/`) — Claude·사용자가 medi_docs 들어올 때 planning 부터 읽고 `sources:` 그래프 따라 내려간다. `_map.md` 가 이 트리를 시각화.

**5) 강제 룰 D1·D4**

| 룰 | 검증 대상 | 위반 시 |
|----|-----------|---------|
| **D1** cut 직전 검증 | `current/` 전체 frontmatter 통과 | **차단** (cut 불가) |
| **D4** lineage 필수 | 모든 비-planning 문서 `sources:` 최소 1개 (retrospective 만 다수 cross-cutting) | **차단** (validate 실패) |

**6) 충족해야 할 책임 4종 (project-agnostic 요구사항)**

이 패턴이 *동작* 하려면 다음 4 책임이 모두 충족되어야 한다. *어느 plugin 의 어느 자산이 어떻게 책임지는가* 는 ADR 단계 결정.

| 책임 | 본질 | 책임 분리 이유 |
|------|------|---------------|
| **R1 scaffold** | 9 카테고리 디렉토리 + README/template + 루트 `_map.md` 시드 *내용물* | "무엇을 채울지" 의 형식 골격 — 내용 |
| **R2 트리거** | `medi_docs/current/**` 변경 시 자동 검증 발동 + scaffold 부재 시 안내 발동 | "언제 검증하나" 의 시점 |
| **R3 검증·인덱싱** | frontmatter·관계 검증 + `_map.md` 자동 갱신 + cut 직전 D1 강제 | "어떻게 검증하나" 의 로직 |
| **R4 메타 노출** | 사용자 repo 의 *Claude 진입점 메타* (예: CLAUDE.md) 에 medi_docs 의 구조·슬래시 명령·hook 동작·진입점 (`planning/` 먼저) 이 안내됨 → 다른 Claude 세션이 그 repo 들어왔을 때 medi_docs 를 *자기 책임으로 인식* | 메타 부재 시 plugin 자산이 박혀도 Claude 가 *외부 디렉토리*로 인식 → 가치 명제 절반만 동작 |

R1·R2·R3 은 sources-04 §1·§3·§6·§7 에서 직접 도출. R4 는 noniterview 기간 누적된 *Claude 가 새 repo 진입 시 CLAUDE.md 만 읽음* 관찰에서 도출 — 이 wiki 합성 시점 (2026-05-01) 누락 발견 후 추가.

4 책임 모두 직교. 어느 하나 빠지면:
- R1 빠짐 → scaffold 안 됨.
- R2 빠짐 → 자동 점검 안 됨 (수동 호출만).
- R3 빠짐 → 검증 로직 자체 부재.
- **R4 빠짐 → Claude 가 medi_docs 를 인식 안 함 — `/medi:version-cut` 호출 안 됨, lineage 룰 무시됨, _map.md 진입 안 함.** "플러그인 깔면 정형 docs 구조 + 자동 매핑 점검" 가치 명제의 *Claude 측 인식* 절반이 빠짐.

**7) cut 동작**

- 트리거: 수동 skill 호출 (`/medi:version-cut`). git tag 자동 연동 X (사용자 git workflow 침범 회피).
- 라벨: 사용자 자유 (`v1.0`, `2026Q2`, `release-2026-04` ...). semver 강제 X.
- 사전 검증 강제: D1 통과 필수, 실패 시 박제 차단.
- 박제: `current/` 전체 → `v{label}/` 복사 + `_map.md` 동결.

**8) uninstall 정책**

- plugin uninstall 시 `medi_docs/` **남김** — 사용자 자산.
- 안내 메시지: "medi_docs/ 는 사용자 자산이라 보존됩니다. 필요 시 직접 삭제하세요."

### 프로젝트 의존 슬롯 (사용자 자율)

같은 골격 위에 *프로젝트별 컨벤션* 슬롯:

**카테고리 활용 깊이 슬롯**
- 작은 프로젝트: 9 카테고리 모두 활용 X — 빈 디렉토리 부담 → 각 README 가 *언제 채울지* 안내. 빈 카테고리 자동 제거는 운영 후 결정.
- 큰 프로젝트: 9 카테고리 + 도메인별 sub-grouping (frontmatter `tags:` 로 표현, 디렉토리는 flat 유지).

**버전 라벨 컨벤션 슬롯**
- semver (`v1.0`, `v1.1`, ...) — 제품·라이브러리 프로젝트.
- 분기 (`2026Q2`, `2026Q3`, ...) — 정책·계획 중심 조직.
- 릴리즈 (`release-2026-04`, ...) — 일자 기반 운영.

**도메인 어휘 슬롯**
- 카테고리 README/template 의 placeholder 어휘를 사용자 도메인으로 교체 (예: `policy/template.md` 에 의료법 vs 금융규제 vs SaaS ToS 어휘).
- harness 가 박는 건 *카테고리 의미와 frontmatter 어휘*, 도메인 어휘는 사용자 책임.

**카테고리 추가 슬롯 (D3 경고 수준)**
- 사용자가 의도적으로 9 카테고리 외 추가 (예: `data-contract/`, `compliance/`) 시 본인 책임. validate 는 경고만, 차단 X.

### 적용 메커니즘 (책임 흐름, 자산 위치는 ADR 결정)

plugin install 후 첫 사용자 시나리오 — *어느 자산이 어떤 책임을 맡는지* 는 ADR 단계에서 결정. 여기서는 *책임의 시간순 흐름* 만 규정:

1. **R2** (트리거) — `harness` 진입 + `medi_docs/` 부재 감지 → 안내 발동.
2. **R1** (scaffold) + **R4** (메타 노출) — 동의 dry-run: "medi_docs/current/ 9 카테고리 + README/template + `_map.md` 생성 **+ 사용자 진입점 메타에 medi-docs 안내 노출**. 진행?"
3. 사용자 동의 → R1 자산 동작 + R4 자산 동작 (둘 모두 idempotent — 재실행 시 외부 사용자 내용 보존).
4. 이후 docs 작성 시 **R2** (트리거) 가 매 Write/Edit 마다 **R3** (검증·인덱싱) 호출 → frontmatter·관계 검증 + `_map.md` 자동 갱신.
5. 마일스톤 도달 시 사용자가 `/medi:version-cut` 호출 → **R3** 가 D1 강제 검증 → `v{label}/` 박제 + `_map.md` 동결. cut 시점에 **R4** 도 동기화 (skill 버전·카테고리 변동 반영) — *권고*, 실제 트리거 위치는 ADR 결정.

이 시퀀스가 R1·R2·R3·R4 4 책임이 한 plugin 안에 묶여야 하는 이유. 어느 하나 빠지면 가치 명제가 부분적으로 깨진다 (§6 참조).

### Open — ADR 단계로 이월

다음은 본 wiki 의 *project-agnostic 요구사항* 범위를 넘어 *plugin 자산 배치·동작 명세* 영역이라 ADR 단계 (`medi-docs-scaffold-to-base`) Decision 섹션에서 결정한다:

- **R4 의 자산 배치 옵션** — (A) templates 자산에 `CLAUDE.md.snippet` 통합 + onboarding skill 의 dry-run 흐름에 augment 단계 끼움 / (B) 별도 `base/skills/medi-docs-claude-md/` skill / (C) 별도 hook 으로 매 변경 시 재생성. (A) 가 *가장 자연* (새 자산 추가 X, 기존 dry-run 동의 흐름 재사용) — ADR Decision 의 출발 가설.
- **R4 마커 블록 형식** — `<!-- medi-docs-managed:start --> ... :end -->` 권장. ADR 에서 형식·escape·다중 plugin 충돌 처리 명세.
- **R4 cut 동기화 정책** — `/medi:version-cut` 사전 단계에 R4 자산 재생성 끼울지 / 별도 명령으로 분리할지.
- **R4 uninstall 정책** — 마커 블록 자동 제거 + 안내 메시지 ("CLAUDE.md 의 medi-docs 안내 섹션 제거됨").
- **R1 의 진입점 메타 파일명 가정** — `CLAUDE.md` 외 사용자가 다른 진입점 메타 (`AGENTS.md` 등) 를 쓰는 경우 R4 가 무엇을 augment 할지. ADR 에서 *발견 우선순위* 또는 *사용자 설정* 결정.

## References

- `sources-04-medi-docs-ssot` (ADR-0008 콘텐츠 부분 발췌 + 관계 4종 어휘 공유 보강)
- 메타 결정: `adr-0008-medi-docs-scaffold` (이 패턴의 메타 결정 원본), `adr-0004-frontmatter-naming` (관계 4종 어휘 정의), `adr-0009-harness-hooks` (H1·H2 hook 결정), `spec-12-medi-docs-tooling` (사용자 배포본 docs-validate 사양), `spec-14-harness-hooks` (hook 등록 메커니즘)
- 다음 단계 (wiki → adr): plugin 매핑 ADR 후보 — `medi-docs-scaffold-to-base` (role = `base`). R1·R2·R3·R4 4 책임이 모두 base plugin 책임 ([[adr-0011-base-hoisting]] §1 + [[adr-0013-hook-precedence]] §1) 이라 단일 ADR 1개로 박는 것이 자연. 자산별로 ADR 갈라지면 lineage 가 끊기고 R4 같은 cross-asset 책임이 *어디에도 안 박힘*.
