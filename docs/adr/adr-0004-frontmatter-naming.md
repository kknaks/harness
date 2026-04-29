---
id: adr-0004
title: Frontmatter Naming
type: adr
status: proposed
date: 2026-04-28
sources:
  - "[[spec-03-frontmatter-naming]]"
tags: [adr]
aliases: []
---

# Frontmatter Naming

## Context

(승격 원본: `docs/spec/spec-03-frontmatter-naming.md`)

기존 `docs-naming` 컨벤션을 5단 콘텐츠 + 3단 메타 전체로 일반화할 필요가 생겼다. Obsidian 호환성(YAML + 위키링크 + tags) 확보와 함께, ADR 은 Michael Nygard 표준 본문(Context / Decision / Consequences)을 사용한다. inbox 만 raw 보존 예외로 처리한다.

## Decision

**파일명**

| 단계 | 패턴 |
|------|------|
| inbox | 원본 그대로 (raw 보존) |
| sources / wiki / harness | `{stage}-NN-{slug}.md` (NN = 2자리) |
| idea / spec | `{type}-NN-{slug}.md` |
| adr (메타·콘텐츠 공통) | `adr-NNNN-{slug}.md` (NNNN = 4자리, 누적 빠름) |

**공통 프론트매터** (모든 단계)
- 필수: `id`, `type` (단계 이름과 일치)
- 관계 4종 (위키링크 리스트): `sources`, `related_to`, `supersedes`, `depends_on`

**spec 추가 필드** (9개 필수): `title`, `status`, `created`, `updated`, `sources`, `owns`, `tags`

**adr 추가 필드** (7개 필수): `title`, `status` (proposed / accepted / superseded / deprecated), `date`, `sources`, `tags`. `owns` 는 두지 않음 (atomic).

**inbox 최소 프론트매터**: `id`, `type: inbox` (1줄씩만 추가).

**본문 스켈레톤**

spec (6 필수 + 2 선택):
```
## Summary / Background / Goals / Non-goals / Design / Open Questions
<!-- 선택: ## Interface / ## Alternatives Considered -->
```

adr (Michael Nygard 표준):
```
## Context / Decision / Consequences
```

## Consequences

**Pros**
- Obsidian + LLM 양쪽이 같은 어휘(id, type, 관계 4종)로 문서를 읽을 수 있다.
- 관계 4종(`sources`, `related_to`, `supersedes`, `depends_on`)이 `_map.md` 자동 인덱싱 기반이 된다.
- ADR 4자리 번호(NNNN)는 빠르게 누적되는 결정 로그에 대비한 설계다.

**Cons**
- 콘텐츠 단계별(inbox / sources / wiki / harness) 추가 필드는 운영 시점에 결정 예정이라, 이후 일관성 유지 부담이 있다.
- inbox raw 보존 예외로 인해 검증 룰이 분기되어 도구 복잡도가 올라간다.

## Notes

_(시간순 append: status 전이, 적용 결과, 후속 학습, 관련 spec 추가 등)_
