---
id: spec-10
title: Medi Docs Scaffold
type: spec
status: decided
created: 2026-04-28
updated: 2026-04-29
sources:
  - "[[idea-03-user-docs-scaffold]]"
owns: medi-docs-scaffold
tags: [spec]
aliases: []
related_to:
  - "[[spec-11-medi-docs-frontmatter]]"
  - "[[spec-12-medi-docs-tooling]]"
depends_on:
  - "[[spec-07-onboarding-skill]]"
---

# Medi Docs Scaffold

## Scope

사용자 프로젝트 `medi_docs/` 의 디렉토리 구조 (9 카테고리, `current/` + `v{label}/` 버전 모델), scaffold 시점, cut 동작, uninstall 처리. frontmatter·template 구체와 도구 셋 명세는 분리.

## Summary

harness plugin 을 설치한 사용자 프로젝트에 `medi_docs/` 를 자동으로 scaffold 하여 9개 카테고리로 구성된 콘텐츠 문서화 표준 공간을 제공한다. `current/` 에서 문서를 작성하고 수동 cut skill 로 `v{label}/` 에 박제하는 버전 모델을 통해 사이클별 의사결정·정책·기획의 시간축 추적을 가능하게 한다.

## Background

harness 가 코드 작성 스킬만 제공하면 반쪽이다. 의사결정·정책·기획을 쌓을 표준 자리가 없으면 각 팀이 제각기 docs 구조를 만들고, Claude 가 매 프로젝트마다 docs 구조를 새로 학습해야 한다 (idea-03 동기). 버전별 디렉토리는 "v1.0 시점의 spec/정책/기획" 스냅샷으로 시간축 추적을 가능하게 한다.

이 문서가 다루는 `medi_docs/` 는 harness 자체의 메타 docs (`docs/idea`, `docs/spec`, `docs/adr`) 와 레이어가 다르다. 전자는 유저 프로젝트가 받는 **콘텐츠 docs**, 후자는 harness 내부의 **메타 docs** 다 (idea-02 레이어 구분). 세 레이어 모두 frontmatter·관계 어휘(`sources`/`related_to`/`supersedes`/`depends_on`)는 동일하지만 `_map.md` 는 분리된다.

## Goals

- 9개 카테고리 풀셋 (`planning`, `plan`, `spec`, `policy`, `adr`, `runbook`, `test`, `release-notes`, `retrospective`) 으로 `medi_docs/current/` 를 scaffold 해 개발 사이클 전체를 커버한다.
- `current/` + `v{label}/` 버전 모델을 채택한다. cut 트리거는 수동 skill, 버전 라벨은 사용자가 자유롭게 지정 (`v1.0`, `2026Q2` 등). git tag 자동 연동 X.
- cut 직후 `current/` 는 그대로 유지 (carry-forward). `v{label}/` 에 박제, `current/` 는 살아있음 → 다음 사이클로 자연 이어짐.
- scaffold 시점은 `[[spec-07-onboarding-skill]]` 의 "처음 셋업" 분기에 통합한다. install hook 강제 X.
- 기존 `docs/` 와 별도 네임스페이스 (`medi_docs/`) 로 공존한다. 충돌 회피.
- cut 직전 검증 통과를 강제한다. 검증 실패 시 박제 차단. `--force` 옵션은 운영 후 결정.
- cut 시 `v{label}/_map.md` 도 함께 박제한다. 그 시점 전체 관계 그래프 보존.
- 사용자 git workflow 를 강제하지 않는다. cut skill 은 파일 시스템만 건드린다. commit/PR 은 사용자 자유. README 에 권장 컨벤션 (cut 결과물 = 1 commit) 만 안내.
- plugin uninstall 시 `medi_docs/` 를 남긴다. 콘텐츠는 사용자 자산. uninstall 안내 메시지로만 처리.
- 카테고리 9개는 역할 무관 공통이다. 역할별 plugin 은 자기 도메인 템플릿/콘텐츠로 기여하며 카테고리 구조 자체는 공유한다.
- 버전 간 차이 추적은 `diff -r v1.0/ v1.1/` 또는 git 으로 충분하다. 별도 diff 도구 X.

## Non-goals

- 9 카테고리 각각의 frontmatter 필드 + 본문 스켈레톤 구체 → `[[spec-11-medi-docs-frontmatter]]`
- 사용자 배포본 도구 셋 (`/medi:new`, `/medi:version-cut`, `docs-validate`) 의 인터페이스·동작 명세 → `[[spec-12-medi-docs-tooling]]`
- 메인테이너용 도구 — 별개 영역
- harness skill 자체 명세 → `[[spec-07-onboarding-skill]]`

## Design

### 디렉토리 구조

```
<user-project>/
└── medi_docs/
    ├── current/                  # 살아있는 작업 상태 (carry-forward)
    │   ├── planning/             # 기획·요구사항·RFP — 무엇을
    │   ├── plan/                 # 마일스톤·스프린트·일정 — 언제·어떻게
    │   ├── spec/                 # 기술 명세 (API, 컴포넌트, 시스템)
    │   ├── policy/               # 도메인 정책·비즈니스 규칙
    │   ├── adr/                  # 결정 로그 (atomic)
    │   ├── runbook/              # 운영 절차·배포 가이드
    │   ├── test/                 # 테스트 시나리오·회귀
    │   ├── release-notes/        # 변경 이력 (사용자용)
    │   ├── retrospective/        # 회고·포스트모템
    │   └── _map.md               # auto (관계 그래프)
    ├── v1.0/                     # cut 시점 박제 (read-only)
    │   ├── planning/ · plan/ · ... · retrospective/
    │   └── _map.md               # 박제된 그래프
    └── v0.9/
        └── ...
```

각 카테고리 디렉토리 안: `README.md` (1-screen 안내) + `template.md` (frontmatter 스키마 + 본문 스켈레톤) + 실제 문서들. 카테고리별 구체 스키마는 `[[spec-11-medi-docs-frontmatter]]` 에서 정의한다.

사이클 매핑: `planning → plan → spec/policy → adr → 구현 → test → release-notes → runbook → retrospective`.

### 동작 흐름

1. 유저가 harness plugin 을 설치한다.
2. `[[spec-07-onboarding-skill]]` 의 "처음 셋업" 분기에서 scaffold 동작:
   - `medi_docs/current/{9 카테고리}/` 생성
   - 각 카테고리에 `README.md` + `template.md` 동봉
   - `current/_map.md` 초기화
   - 이미 `medi_docs/` 가 존재하면 no-op (기존 자산 보호)
3. 유저가 `current/` 안에서 문서를 작성한다. 새 문서 생성 및 frontmatter 검증 도구의 인터페이스는 `[[spec-12-medi-docs-tooling]]` 에서 정의한다.
4. 새 작업 사이클 시작 시 version-cut 을 호출한다. 스킬이 버전 라벨을 명시적으로 묻고:
   - cut **직전** 검증 통과 강제. 실패 시 차단.
   - `current/` 전체 → `v{label}/` 으로 복사·박제 (`_map.md` 포함)
   - `current/` 는 그대로 유지 (carry-forward) → 다음 사이클 incremental
5. 이후 `v{label}/` 은 read-only. 버전 간 차이 추적은 `diff -r v1.0/ v1.1/` 또는 git 으로 처리.
6. plugin uninstall 시 `medi_docs/` 를 남긴다 (사용자 자산). uninstall 안내 메시지로만 처리.

## Open Questions

- [ ] cut 결과물에 대한 자동 commit 옵션 (`--commit` 플래그 등) 도입 여부 — 현재는 사용자 자유이나 운영 패턴 파악 후 spec-12 또는 이 spec 에서 결정.
