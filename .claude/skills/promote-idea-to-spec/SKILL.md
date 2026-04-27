---
name: promote-idea-to-spec
description: idea 를 spec 으로 승격하거나 기존 spec 으로 병합한다. 프론트매터의 sources 리스트로 lineage, related_to/supersedes/depends_on 으로 그래프 관계를 추적. 사용자가 "idea-NN 을 spec 으로" 또는 "idea-NN 을 spec-MM 에 합쳐" 같은 요청을 할 때 사용.
---

# Promote / Merge Idea → Spec

30 idea ↛ 30 spec. 합쳐지거나, 중복으로 버려지거나, 일부만 spec 으로 굳는다. 추적은 spec 프론트매터의 다음 필드들로:

- `sources` (필수, 1개 이상) — 흡수한 idea 위키링크 리스트 (lineage)
- `related_to` (선택) — 양방향 소프트 링크
- `supersedes` (선택) — 단방향 하드 링크 (이 spec 이 다른 문서를 대체)
- `depends_on` (선택) — 단방향 의존 관계

`docs/_map.md` 의 Relations 섹션이 이 모두를 양방향 인덱싱 (`docs-validate` 가 자동 재생성).

## When to use

- **새 spec 으로 승격**: idea 가 처음 SSOT 토픽이 될 때.
- **기존 spec 에 병합**: 다른 idea 가 이미 있는 spec 의 같은 주제를 다룰 때.

idea 파일은 항상 보존. 추적의 단방향 진실은 spec 의 frontmatter.

## Steps — 새 spec 으로 승격

1. **소스 확인** — idea 파일 존재 + `id`/`type` 프론트매터 보유.
2. **번호 산정** — `docs/spec/` 내 max NN + 1.
3. **`owns` 합의** — 사용자와 topic 이름 (kebab-case).
4. **스캐폴드** — `scripts/promote.sh <idea>` → 9개 필수 필드 포함 spec 생성.
5. **(선택) 관계 추가** — `related_to`/`supersedes`/`depends_on` 필요 시 손으로 추가.
6. **검증 + _map 재생성** — `docs-validate/scripts/validate.sh`.
7. **보고** — 경로, owns, 검증 결과.

## Steps — 기존 spec 에 병합

1. **대상 확인** — idea + spec 둘 다 존재.
2. **사용자 확인** — "정말 같은 주제?" 한 번 묻기.
3. **머지** — `scripts/merge.sh <idea> <spec>` → spec 의 `sources` 에 추가, `updated` 갱신.
4. **본문 통합** — idea 의 핵심을 spec 본문에 반영 (수동).
5. **검증 + _map 재생성** — `docs-validate/scripts/validate.sh`.
6. **보고** — 갱신된 sources, _map 변경.

## Frontmatter Schema (spec)

`examples/spec-01-cli-shape.md` 가 정본 (관계 4종 모두 포함한 예).

| 필드 | 필수 | 값 |
|------|------|-----|
| `id` | ✓ | `spec-NN` |
| `title` | ✓ | 제목 |
| `type` | ✓ | `spec` |
| `status` | ✓ | `draft` \| `active` \| `deprecated` |
| `created` | ✓ | `YYYY-MM-DD` |
| `updated` | ✓ | `YYYY-MM-DD` |
| `sources` | ✓ | 흡수한 idea 위키링크 리스트 (1개 이상) |
| `owns` | ✓ | SSOT topic (유일) |
| `tags` | ✓ | 최소 `[spec]` |
| `aliases` | - | Obsidian alias |
| `related_to` | - | 양방향 소프트 링크 (idea/spec 모두 가능) |
| `supersedes` | - | 이 spec 이 대체하는 문서 |
| `depends_on` | - | 이 spec 이 의존하는 spec |

`sources` 블록 형식:
```yaml
sources:
  - "[[idea-02-cli-shape]]"
  - "[[idea-07-shell-completion]]"
```

## Body Skeleton

```
# <Title>

## Goal
## Non-goals
## Design
## Open Questions
```

## Scripts

- `scripts/promote.sh <idea>` — 새 spec 생성.
- `scripts/merge.sh <idea> <spec>` — 기존 spec 의 sources 에 idea 추가 (멱등).

## Checklist

`checklist.md`.

## Don't

- idea 파일 삭제 금지 — 모든 관계 위키링크가 끊김.
- `docs/_map.md` 직접 편집 금지 — 자동 생성물.
- 동일 `owns` 가 다른 spec 에 있으면 새로 만들지 말고 병합.
- `supersedes`/`depends_on` 사이클 금지 — validate 가 잡지만 처음부터 만들지 말 것.
- 번호 재사용 금지.
