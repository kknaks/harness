---
id: spec-02
title: Directory Structure
type: spec
status: decided
created: 2026-04-28
updated: 2026-04-28
sources:
  - "[[idea-02-mediness-architecture]]"
  - "[[idea-01-distribution-strategy]]"
owns: directory-structure
tags: [spec]
aliases: []
---

# Directory Structure

## Scope

하네스 레포의 디렉토리 트리 — docs/ + content/ + content/harness 의 plugin 모노레포 영역. 파일 컨벤션·권한·도구는 다른 spec.

## Summary

메타와 콘텐츠를 형제 디렉토리(`docs/`, `content/`)로 분리하고, 메타 레이어를 3단(idea → spec → adr)으로 확장한다. 각 레이어는 자기 `_map.md` 를 보유한다.

## Background

5단 콘텐츠 파이프라인이 idea/spec 수준의 메타 의사결정과 다른 lifecycle 을 가지므로 레이어 분리 필요. 메타 레이어도 ADR 도입으로 idea→spec→adr 3단 대칭. (idea-02)

## Goals

- 메타(`docs/`) ↔ 콘텐츠(`content/`) 분리
- 메타 3단 도입: `docs/idea/` → `docs/spec/` → `docs/adr/`
- 레이어별 `_map.md` 보유
- `content/harness/` = distribution monorepo (6 role plugin + base + marketplace.json)
- 레이어 간 참조 금지

## Non-goals

- 단계별 파일명·프론트매터 — `[[spec-03-frontmatter-naming]]`
- 권한·노출 정책 — `[[spec-04-permissions-flow]]`
- plugin 자산 hoisting — `[[spec-06-base-hoisting]]`
- 사용자 onboarding 스킬 — `[[spec-07-onboarding-skill]]`
- hook 실행 순서 — `[[spec-08-hook-precedence]]`
- 버전·롤백 — `[[spec-09-version-rollout]]`

## Design

```
{repo-root}/                          (mediness 사내 모노레포)
├── docs/                             ← 메타 (3단)
│   ├── _map.md
│   ├── idea/ · spec/ · adr/
├── content/                          ← 콘텐츠 (5단)
│   ├── _map.md
│   ├── inbox/ · sources/ · wiki/ · adr/
│   └── harness/                      ← 5단 마지막 = distribution monorepo
│       ├── .claude-plugin/
│       │   └── marketplace.json      ← 모든 plugin 등록
│       └── plugins/
│           ├── base/                 ← 모든 역할 공통
│           ├── planning/ · pm/
│           ├── frontend/ · backend/
│           └── qa/ · infra/
├── CODEOWNERS                        ← 영역별 자동 리뷰어
├── CONTRIBUTING.md
└── .github/workflows/                ← CI 검증, 자동 릴리즈
```

**`_map.md` 두 개** — 동일 schema/format/검증 도구. 레이어별 독립 인덱스.

**메타 3단**: `idea` 자유 thoughts → `spec` 조율 중 → `adr` 확정. 콘텐츠 5단(inbox→sources→wiki→adr→harness)과 어휘 대칭.

**`content/harness/` = distribution monorepo** (idea-01 통합)
- 5단 마지막 단계가 곧 사내 plugin 모노레포 본체. `content/harness/` 와 idea-01 의 "harness 모노레포" 는 같은 디렉토리.
- 사용자: `claude plugin marketplace add github:medisolve/harness` → 본인 역할 plugin install.
- 거버넌스: 단일 repo PR, CODEOWNERS 영역별 리뷰어.

**Role plugin 책임 예시** (확정 아님, 운영하며 형성)

| Plugin | 담는 것 (예시) |
|--------|----------------|
| `base` | 회사 CLAUDE.md, 시크릿 차단 훅, 커밋 컨벤션, 메타 도구 |
| `planning` | 기획서 템플릿, RFP, 시장 분석 |
| `pm` | 일정 추적, 회의록, 진행 보고 |
| `frontend` | React/Next/Vite 컨벤션, 컴포넌트, 디자인 토큰 |
| `backend` | API 설계, DB 마이그레이션, Python/PG 패턴 |
| `qa` | 테스트 시나리오, 회귀 체크, 결함 분류 |
| `infra` | 배포·CI/CD, k8s/Terraform, 시크릿 관리 |

## Open Questions

- [ ] `harness/` 를 `content/` 안에 둘지, 레포 루트로 분리 노출할지 (배포 단위 고려)
