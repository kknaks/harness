# Docs-Naming Rules

> 스킬이 강제하는 룰셋. SKILL.md (사용자 시점 진입점) 가 trigger 시 로드 → 본 rules.md 는 신규 자산 생성·스키마 점검 시 지연 로드 ([[adr-0007-skill-authoring-rules]] §1).

## File Name 규칙

```
{type}-{NN}-{title}.md      # idea / spec / sources / wiki / harness
adr-{NNNN}-{title}.md       # adr (메타·콘텐츠 공통, 4자리)
```

- `{type}` — `idea` / `spec` / `inbox` / `sources` / `wiki` / `adr` / `harness`
- `{NN}` — 2자리 일련번호 (디렉토리별 독립, 단조 증가). 100 도달 시 자연 NNN 확장 — 정규식 `^{type}-([0-9]+)-` 가 흡수.
- `{NNNN}` — adr 만 4자리 (MADR 외부 표준 호환, [[adr-0004-frontmatter-naming]] §1).
- `{title}` — kebab-case (영문 소문자 + 숫자 + `-`).

예:
- `docs/idea/idea-02-cli-shape.md`
- `docs/spec/spec-01-cli-shape.md`
- `docs/adr/adr-0011-base-hoisting.md`
- `content/wiki/wiki-01-code-review-pattern.md`
- `content/adr/adr-0001-code-review-to-backend.md`

규칙:
1. 번호는 디렉토리별로 독립 (`docs/idea/` / `docs/spec/` / `docs/adr/` / `content/sources/` / `content/wiki/` / `content/adr/` 각자).
2. 번호는 한 번 부여되면 재사용 X (폐기되어도 비워둔다).
3. 단계 간 승격 시 번호 일치시키지 않는다 (예: `idea-02` → `spec-NN` — NN 은 spec 의 다음 숫자).
4. 메타 ADR (`docs/adr/`) 와 콘텐츠 ADR (`content/adr/`) 는 카운터 분리.

## Frontmatter (모든 문서 공통 최소)

| 필드 | 필수 | 값 |
|------|------|-----|
| `id` | ✓ | `{type}-{NN}` 또는 `adr-{NNNN}` (파일명의 NN과 동일) |
| `type` | ✓ | `idea` / `spec` / `inbox` / `sources` / `wiki` / `adr` / `harness` (디렉토리와 일치) |

추가 필드는 type 별로 다름 (자세한 명세는 [[adr-0004-frontmatter-naming]] §R4-R10).

### idea (선택 필드)

| 필드 | 비고 |
|------|------|
| `created` | `YYYY-MM-DD` (권장) |
| `status` | `open` (default) / `absorbed` / `archived` / `superseded` — 흡수 시 `absorbed` 갱신 |
| `tags` | 최소 `[idea]` (권장) |
| `categories` | 자유 enum, 다중 (선택) — [[adr-0003-content-pipeline]] §categories |
| `related_to` | 위키링크 리스트 — 양방향 소프트 링크 |
| `supersedes` | 위키링크 리스트 — 이 idea 가 대체하는 다른 idea/spec |
| `depends_on` | 위키링크 리스트 — 이 idea 가 의존하는 spec |

### spec (필수 9개 + 선택 4개)

자세히는 `promote-docs/rules.md` §Frontmatter Schema (spec).

### adr (필수 7개 + 선택)

`id` / `title` / `type` / `status` / `date` / `sources` / `tags`. 콘텐츠 ADR (`content/adr/`) 은 추가로 `categories` / `role` *권장* — [[adr-0011-base-hoisting]] §1 enum.

## Status enum

자세히는 `docs-validate/rules.md` §검사 대상 필드 §status enum.

## How to apply (새 idea 생성)

1. `scripts/new-idea.sh "<title>"` 실행 → 다음 NN 산정 + 프론트매터 포함 idea 파일 생성 + 경로 출력.
2. 본문에 사용자가 준 메모 작성.
3. 다른 idea/spec 와 관계가 있으면 frontmatter 의 `related_to` / `supersedes` / `depends_on` 추가.
4. `docs-validate/scripts/validate.sh` 로 검증 (PostToolUse 훅이 자동으로 실행하기도 함).

spec 파일 생성은 `promote-docs` 스킬 (idea→spec 승격) 사용. ADR 생성도 `promote-docs` (`spec-to-adr.sh` / `wiki-to-adr.sh`).

## Don't

- 번호 재사용 금지 (폐기되어도 비워둔다).
- 메타·콘텐츠 ADR 카운터 섞기 금지.
- 단계 간 승격 시 번호 일치시키지 않기 (`idea-02` ≠ `spec-02`).
- 파일명 한글·공백·대문자 금지 (kebab-case 강제).
