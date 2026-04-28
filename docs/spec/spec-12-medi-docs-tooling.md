---
id: spec-12
title: Medi Docs Tooling
type: spec
status: draft
created: 2026-04-28
updated: 2026-04-28
sources:
  - "[[idea-03-user-docs-scaffold]]"
owns: medi-docs-tooling
tags: [spec]
aliases: []
related_to:
  - "[[spec-10-medi-docs-scaffold]]"
depends_on:
  - "[[spec-02-directory-structure]]"
  - "[[spec-06-base-hoisting]]"
---

# Medi Docs Tooling

## Scope

사용자 배포본 도구 셋(`/medi:new` · `/medi:version-cut` · `docs-validate`)의 인터페이스·동작·base plugin 패키징을 명세한다. 메인테이너용 도구(`docs-naming`, `promote-docs`, 메인테이너용 `docs-validate`)는 이 spec 의 대상이 아니다.

## Summary

harness plugin 을 설치한 사용자 팀이 `medi_docs/` 안에서 문서를 생성·검증·버전 박제하는 데 사용하는 도구 3개(`/medi:new`, `/medi:version-cut`, `docs-validate`)를 정의하고, 이 도구들이 base plugin 안에 메인테이너용 도구와 분리된 별개 산출물로 패키징됨을 명세한다.

## Background

idea-02 의 권한 모델은 harness 의 레이어를 세 가지로 구분한다.

| 레이어 | 위치 | 누가 만지나 | 무엇 |
|--------|------|-------------|------|
| harness 메타 | (harness repo) `docs/idea` `docs/spec` `docs/adr` | harness 메인테이너 | harness 자체에 대한 의사결정 |
| harness 콘텐츠 | (harness repo) `content/inbox` … `content/harness` | harness 메인테이너 | 5단 파이프라인 |
| 유저 medi_docs | (user repo) `medi_docs/current/` + `v{label}/` | 유저 팀 (6 role) | 유저 프로젝트의 9 카테고리 산출물 |

이 레이어 구분에서 핵심 원칙이 도출된다: **작성 도구는 재사용하지 않는다.** 메인테이너용 `.claude/skills/docs-validate`와 `docs-naming`은 idea-02 의 권한 모델에 따라 사용자에게 노출되지 않는 내부 작업장 도구다. 사용자용 도구는 5단 파이프라인([[spec-06-base-hoisting]] 참조)을 통과한 결과물로 base plugin 안에 별도 패키징된다. 핵심 로직 공유 여부는 코드 중복이 실제 문제로 떠오를 때 별도 결정한다.

사용자가 도구를 접하는 진입점은 `harness` skill([[spec-07-onboarding-skill]])의 "처음 셋업" 분기에서 `medi_docs/` scaffold([[spec-10-medi-docs-scaffold]])가 생성된 이후다. 각 도구가 다루는 문서 frontmatter·본문 스켈레톤 규칙은 [[spec-11-medi-docs-frontmatter]]가 소유하고, base plugin 디렉토리 구조상의 위치는 [[spec-02-directory-structure]]가 결정한다.

## Goals

- `/medi:new <category> <slug>` — 사용자가 `medi_docs/current/` 안에서 새 문서를 생성하는 단일 진입점 제공. NN 자동 부여, frontmatter 채움, 카테고리 `template.md` 기반 본문 스켈레톤 복사.
- `/medi:version-cut` — 버전 라벨을 대화형으로 받아 `current/` 전체를 `v{label}/`로 박제. cut 직전 검증 통과를 강제하여 깨끗한 스냅샷만 허용.
- `docs-validate` (사용자 배포본) — base plugin 안 별도 산출물로, frontmatter·관계 검증과 `_map.md` 자동 갱신을 담당. 메인테이너용 `.claude/skills/docs-validate`와 분리.
- 메인테이너용 도구와 사용자 배포본을 완전히 분리하여 idea-02 권한 모델 준수.

## Non-goals

- 디렉토리 구조 / scaffold / cut 모델 자체 → [[spec-10-medi-docs-scaffold]]
- 9 카테고리 frontmatter / 본문 스켈레톤 → [[spec-11-medi-docs-frontmatter]]
- 메인테이너용 도구 (`docs-naming`, 메인테이너 `docs-validate`, `promote-docs`) — 별개 spec 영역
- base plugin 자체 자산 정책 → [[spec-06-base-hoisting]]
- harness skill 자체 → [[spec-07-onboarding-skill]]

## Design

### 도구 셋 개요

사용자 배포본 도구는 현재 3개로 시작한다 (M1 결정: YAGNI, 추가 도구는 사용 패턴 확인 후).

| 도구 | 종류 | 인자 | 핵심 동작 | 검증 강제 |
|------|------|------|-----------|-----------|
| `/medi:new` | 슬래시 커맨드 | `<category> <slug>` | NN 자동 부여 + frontmatter 채움 + `template.md` 기반 본문 스켈레톤 복사 | 카테고리 유효성 확인 |
| `/medi:version-cut` | 슬래시 커맨드 | 없음 (대화형 라벨 입력) | cut 직전 검증 통과 강제 → `current/` 전체를 `v{label}/`로 복사·박제 → `v{label}/_map.md` 함께 박제 | **차단** (검증 실패 시 cut 불가) |
| `docs-validate` (배포본) | 훅 / 자동 실행 | 없음 | frontmatter·관계 검증 + `_map.md` 자동 갱신 | frontmatter 누락 = 차단; 본문 섹션 누락 = 경고 |

### 메인테이너용 vs 사용자 배포본 비교

| 항목 | 메인테이너용 | 사용자 배포본 |
|------|-------------|--------------|
| 위치 | `.claude/skills/docs-validate`, `.claude/skills/docs-naming` 등 | base plugin 안 (경로는 [[spec-02-directory-structure]] 기준) |
| 노출 대상 | harness 메인테이너 | 플러그인 설치 사용자 팀 |
| 파이프라인 | 직접 사용 (내부 작업장) | 5단 파이프라인([[spec-06-base-hoisting]]) 통과 후 배포 |
| 로직 공유 | — | 중복이 실제 문제 될 때 결정 (현재 분리) |

### `/medi:new` 동작 상세

1. `<category>` 인자가 9개 카테고리 중 하나인지 확인. 아니면 오류 출력 후 종료.
2. 해당 카테고리 디렉토리 안 기존 파일의 NN 최댓값 확인 → +1 로 새 번호 부여.
3. 카테고리 `template.md`를 복사하여 `{category}-{NN}-{slug}.md` 생성.
4. frontmatter의 `id`, `type`, `created` 필드를 자동 채움.
5. 사용자에게 생성된 파일 경로 출력.

### `/medi:version-cut` 동작 상세

1. 버전 라벨을 대화형으로 입력받음 (예: `v1.0`, `2026Q2` — 형식은 사용자 자유).
2. `docs-validate` (배포본)를 실행하여 `current/` 전체 검증. 실패 시 **차단** (M3: `--force` 옵션은 운영 후 결정).
3. 검증 통과 시 `current/` 전체를 `v{label}/`로 복사·박제. `_map.md` 포함.
4. `current/`는 carry-forward — 그대로 유지하여 다음 사이클 작업 지속.
5. `v{label}/`은 이후 read-only 취급. git 커밋·PR 은 사용자 자유 (강제 X). README 에 cut 결과물 = 1 commit 권장 컨벤션 안내 (M6).

### `docs-validate` (사용자 배포본) 동작 상세

- 훅 또는 skill 내부에서 자동 실행 (사용자가 직접 슬래시 커맨드로 호출하는 방식 아님).
- 검증 항목: frontmatter 필수 필드 존재 여부 (`id`, `type`, 관계 어휘), 관계 링크 대상 파일 실존 여부.
- `_map.md` 자동 갱신 (관계 그래프).
- frontmatter 누락 → 차단. 본문 섹션 누락 → 경고만.

## Interface

### `/medi:new`

```
/medi:new <category> <slug>
```

- `category`: `planning` · `plan` · `spec` · `policy` · `adr` · `runbook` · `test` · `release-notes` · `retrospective` 중 하나
- `slug`: kebab-case 문자열 (예: `auth-flow`, `deploy-guide`)
- 출력: 생성된 파일 경로 (`medi_docs/current/{category}/{category}-{NN}-{slug}.md`)

### `/medi:version-cut`

```
/medi:version-cut
```

- 인자 없음. 실행 후 버전 라벨을 대화형으로 입력받음.
- 라벨 형식 자유 (예: `v1.0`, `2026Q2`).
- 검증 실패 시 cut 차단, 오류 내용 출력. `--force` 미지원 (운영 후 결정).

### `docs-validate` (사용자 배포본)

- 슬래시 커맨드 없음. 훅 또는 `/medi:version-cut` 내부에서 자동 호출.
- 결과: 성공 (통과) / 경고 (본문 섹션 누락) / 차단 (frontmatter 누락 또는 관계 링크 불일치).

## Open Questions

- [ ] M1 — 도구 추가 트리거: `version-list` / `category-add` / `lint` 등 추가 도구의 도입 기준을 사용 패턴 어느 시점에서 판단할 것인가? (현재 YAGNI)
- [ ] M3 — `--force` 도입 기준: cut 검증 실패 시 강제 박제가 실제로 필요한 운영 상황이 발생하면 `--force` 옵션 도입. 판단 기준 및 도입 조건은 운영 후 결정.
