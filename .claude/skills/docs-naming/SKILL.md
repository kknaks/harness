---
name: docs-naming
description: docs/ 하위 문서의 파일명 + 프론트매터 규칙. idea 새로 만들 때, 또는 파일명/스키마를 점검할 때 사용.
---

# Docs Naming & Authoring

`docs/` 하위 모든 문서는 (1) 파일명 규칙, (2) 최소 프론트매터, 둘 다 따른다.

## File Name

```
{type}-{NN}-{title}.md
```

- `{type}` — `idea` 또는 `spec`
- `{NN}` — 2자리 일련번호 (디렉토리별 독립, 단조 증가)
- `{title}` — kebab-case (영문 소문자 + 숫자 + `-`)

예: `docs/idea/idea-02-cli-shape.md`, `docs/spec/spec-01-cli-shape.md`.

규칙:
1. 번호는 `idea/`, `spec/` 디렉토리별로 독립.
2. 번호는 한 번 부여되면 재사용 X (폐기되어도 비워둔다).
3. idea→spec 승격 시 번호 일치시키지 않는다.

## Frontmatter (모든 문서 공통 최소)

| 필드 | 필수 | 값 |
|------|------|-----|
| `id` | ✓ | `{type}-{NN}` (파일명의 NN과 동일) |
| `type` | ✓ | `idea` 또는 `spec` (디렉토리와 일치) |

추가 필드는 type 별로 다름:

### idea (선택 필드)

| 필드 | 비고 |
|------|------|
| `created` | `YYYY-MM-DD` (권장) |
| `status` | `open` (default) / `absorbed` / `archived` / `superseded` — 흡수 시 `absorbed` 갱신 |
| `tags` | 최소 `[idea]` (권장) |
| `related_to` | 위키링크 리스트 — 양방향 소프트 링크 |
| `supersedes` | 위키링크 리스트 — 이 idea 가 대체하는 다른 idea/spec |
| `depends_on` | 위키링크 리스트 — 이 idea 가 의존하는 spec |

### spec (필수 필드 9개)

`promote-docs/SKILL.md` 참고. 추가로 `related_to`/`supersedes`/`depends_on` 선택.

## Scripts

- `scripts/new-idea.sh "<title>"` — 다음 NN 산정 + 프론트매터 포함 idea 파일 생성.

spec 파일 생성은 `promote-docs` 스킬 사용.

## Examples

- `examples/idea-02-cli-shape.md` — 관계 선언이 있는 idea
- `../promote-docs/examples/spec-01-cli-shape.md` — 관계 선언이 있는 spec

## How to apply

새 idea 요청을 받으면:
1. `scripts/new-idea.sh "<title>"` 실행 → 경로 출력
2. 본문에 사용자가 준 메모 작성
3. 다른 idea/spec 와 관계가 있으면 frontmatter 의 `related_to` / `supersedes` / `depends_on` 추가
4. `docs-validate/scripts/validate.sh` 로 검증 (PostToolUse 훅이 자동으로 실행하기도 함)
