---
id: spec-11
title: Medi Docs Frontmatter
type: spec
status: accepted
created: 2026-04-28
updated: 2026-04-29
sources:
  - "[[idea-03-user-docs-scaffold]]"
owns: medi-docs-frontmatter
tags: [spec]
aliases: []
related_to:
  - "[[spec-03-frontmatter-naming]]"
  - "[[spec-10-medi-docs-scaffold]]"
  - "[[adr-0008-medi-docs-scaffold]]"
---
엥 
# Medi Docs Frontmatter

## Scope

medi_docs 9 카테고리의 frontmatter 필드 + 본문 스켈레톤 + 검증 차등. 메타·콘텐츠 frontmatter 는 [[spec-03-frontmatter-naming]].

## Summary

medi_docs 9 카테고리가 공유하는 frontmatter 어휘, 파일명 패턴, 본문 스켈레톤 base 모델, 검증 차등 원칙을 정의한다. 자매 spec [[spec-03-frontmatter-naming]] 의 어휘를 재사용하며 medi_docs 전용 새 어휘는 추가하지 않는다.

## Background

harness plugin 을 설치한 사용자(팀)는 `medi_docs/current/` 아래 9 카테고리에 걸쳐 문서를 작성한다. 카테고리마다 frontmatter 스키마·본문 양식이 제각기 자유롭게 결정되면 Claude 가 매 프로젝트마다 구조를 새로 학습해야 하고, `/medi:new` 자동화나 `docs-validate` 검증도 불가능해진다 (idea-03 동기).

spec-03([[spec-03-frontmatter-naming]])이 정의한 `id`, `type`, 관계 4종(`sources` / `related_to` / `supersedes` / `depends_on`)은 harness 메타 docs 와 사용자 medi_docs 레이어 모두에서 동일하게 쓰인다 (idea-03 레이어 구분표). 이 spec 은 그 공통 어휘를 9 카테고리에 적용하는 원칙을 다룬다.

idea-02 권한 모델에 따라 사용자 배포본 도구(`/medi:new`, `docs-validate` 사용자판)는 harness 메인테이너용 `.claude/skills/` 도구와 분리된 별도 산출물로 패키징된다. 도구 명세는 [[spec-12-medi-docs-tooling]], scaffold 동작은 [[spec-10-medi-docs-scaffold]] 참조.

## Goals

- 9 카테고리 모두 spec-03 공통 어휘(`id`, `type`, 관계 4종)를 그대로 사용하여 medi_docs 전용 어휘를 0으로 유지한다.
- 카테고리 이름을 `type` 값으로 삼아 파일 위치와 frontmatter 가 자기 설명적이 되도록 한다.
- 9 카테고리를 *spec계* / *adr계* 두 base 모델 중 하나에 귀속시켜 본문 스켈레톤의 다양성을 최소화한다.
- 각 카테고리에 `template.md` 를 단일 진실 원천으로 두어 양식 변경 시 한 파일만 수정하면 전파되도록 한다.
- frontmatter 누락은 `docs-validate` 가 차단하고 본문 누락은 경고만 내어 엄격함과 실용성 사이 균형을 맞춘다.

## Non-goals

- 9 카테고리 각각의 구체 필드 셋 (`spec` 의 `status` 종류, `release-notes` 의 `version` 형식 등) — 운영 후 결정. 이 spec 은 원칙만 다룬다.
- 디렉토리 구조·scaffold 생성·version cut 동작 → [[spec-10-medi-docs-scaffold]]
- 사용자 배포본 도구(`/medi:new`, `/medi:version-cut`, `docs-validate`) 인터페이스 명세 → [[spec-12-medi-docs-tooling]]
- harness 메타 docs(harness repo 의 `docs/idea`, `docs/spec`) 의 frontmatter 어휘 — 이미 [[spec-03-frontmatter-naming]] 이 owns.

## Design

### 원칙 7개 (M2)

| # | 원칙 | 내용 |
|---|------|------|
| 1 | 공통 프론트매터 | 9 카테고리 모두 spec-03 공통 어휘(`id`, `type`, `sources` / `related_to` / `supersedes` / `depends_on`) 그대로 사용. medi_docs 전용 새 어휘 추가 X |
| 2 | 카테고리 = type | `type: spec`, `type: policy`, `type: adr` … 카테고리 이름이 `type` 값 (spec-03 패턴 재사용) |
| 3 | 파일명 패턴 | `{category}-NN-{slug}.md`. ADR 만 4자리: `adr-NNNN-{slug}.md` |
| 4 | 본문 스켈레톤 base 모델 | spec계(`Summary / Background / Goals / Design / Open Questions`) 와 adr계(`Context / Decision / Consequences`) 두 개. 9 카테고리는 아래 표에 따라 귀속 |
| 5 | 카테고리별 추가 필드 최소화 | 의미상 꼭 필요한 것만 (예: `release-notes` 의 `version`/`date`). 불필요 필드 X |
| 6 | `template.md` = 단일 진실 원천 | 카테고리마다 `template.md` 동봉. `/medi:new` 가 이를 복사. 양식 변경 시 `template.md` 만 수정 |
| 7 | 검증 차등 | frontmatter 필드 누락 → `docs-validate` **차단**. 비-planning 문서 `sources:` 누락 → **차단** ([[adr-0008-medi-docs-scaffold]] §6 D4). 본문 섹션 누락 → **경고**만 (강제 X) |

### 카테고리별 base 모델 귀속

| base 모델 | 카테고리 | 수 |
|-----------|----------|----|
| spec계 (`Summary / Background / Goals / Design / Open Questions`) | `spec`, `policy`, `planning`, `plan`, `runbook`, `test`, `release-notes` | 7 |
| adr계 (`Context / Decision / Consequences`) | `adr`, `retrospective` | 2 |

### cross-reference 어휘

카테고리 간 관계는 idea-02 에서 확정된 4종 어휘를 그대로 사용한다. medi_docs 전용 어휘는 없다.

| 어휘 | 방향 | 예시 |
|------|------|------|
| `sources` | 파생 출처 (spec→planning, adr→spec lineage) | `sources: ["[[spec-01-api]]"]` |
| `related_to` | 비계층 참조 | `related_to: ["[[policy-02-auth]]"]` |
| `supersedes` | 이전 문서 대체 | `supersedes: ["[[adr-0003-db-choice]]"]` |
| `depends_on` | 선행 의존 | `depends_on: ["[[spec-03-payment]]"]` |

### 진입점·lineage 위계 ([[adr-0008-medi-docs-scaffold]] §7)

frontmatter `sources:` 어휘로 위계를 표현한다. 디렉토리는 평면 9 카테고리, 위계 깊이는 `sources:` 그래프로만.

| 카테고리 | sources 룰 | 비고 |
|----------|-----------|------|
| `planning` | 비어있어도 됨 (root). 외부 (비전·RFP 등) 자유 형식 허용 | **단일 진입점** |
| `policy` | 최소 1개, 보통 `[[planning/...]]` | planning 자식 |
| `plan` | 최소 1개, 보통 `[[planning/...]]` | planning 자식 |
| `spec` | 최소 1개, 보통 `[[plan/...]]` | plan 파생 |
| `adr` | 최소 1개, `[[spec/...]]` 또는 `[[plan/...]]` | 결정 lineage |
| `test` | 최소 1개, 보통 `[[spec/...]]` | 검증 대상 |
| `runbook` | 최소 1개, 보통 `[[spec/...]]` | 운영 대상 |
| `release-notes` | 최소 1개, 보통 `[[plan/...]]` | cut 시점 산출 |
| `retrospective` | 다수 cross-cutting (planning/plan/spec 등 여러 개) | 회고 대상 자유 |

강제는 [[adr-0008-medi-docs-scaffold]] §6 D4 (`docs-validate` 차단) — 원칙 7 (검증 차등) 의 차단 항목에 포함.

## Open Questions

- [x] ADR 만 파일명 번호가 4자리(`adr-NNNN`)이고 나머지 카테고리는 2자리(`{category}-NN`)인 것이 일관성 원칙에 맞는가 — **결정 (2026-04-29, 옵션 B 채택)**: ADR 만 4자리 유지. 이유: harness 메타 ADR (`adr-0001`~`adr-0008`) 이 이미 4자리로 굳어있어 medi_docs 사용자 ADR 과 mental model 동일 + ADR 만 누적량이 길어지는 카테고리 (다른 카테고리는 한 프로젝트 라이프타임 100개 미만 → 2자리 충분) + NN 자릿수 = 카테고리 수명 신호.
- [x] 카테고리별 추가 필드(원칙 5)의 최소성 기준을 이 spec 이 정의해야 하는가 — **결정 (2026-04-29, 후자 채택)**: spec-11 = 원칙만 (원칙 5: "꼭 필요한 것만"). 구체 필드 셋은 각 카테고리별 spec (해당 카테고리 `owns` 갖는 spec) 에서 결정. 경계 명시: 이 spec 은 *어휘·base 모델·검증 차등* 까지만, 카테고리 N 의 *어떤 status 값이 있는지* 는 카테고리 N spec.
