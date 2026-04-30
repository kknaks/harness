# Docs-Validate Rules

> 스킬이 강제하는 룰셋. SKILL.md (사용자 시점 진입점) 가 trigger 시 로드 → 본 rules.md 는 위반 발견·수정 절차 시 지연 로드 ([[adr-0007-skill-authoring-rules]] §1).

## Checks (차단)

| # | 검사 | 위반 코드 |
|---|------|-----------|
| R1 | idea 필수 필드 (`id`, `type`) | `missing-frontmatter` |
| R2 | spec 필수 9개 필드 | `missing-frontmatter` |
| R2b | adr 필수 7개 필드 (`id`, `title`, `type`, `status`, `date`, `sources`, `tags`) | `missing-frontmatter` |
| R3 | 프론트매터 자체가 없는 경우 | `no-frontmatter` |
| R4 | `type` 이 디렉토리와 일치 | `type-mismatch` |
| R5 | `id` 유일성 (전체) | `dup-id` |
| R6 | `owns` 유일성 (spec) | `dup-owns` |
| R7 | spec/adr.sources 비어있지 않음 | `no-sources` |
| R8 | spec.sources → idea-*, adr.sources → spec-* | `bad-source-kind` |
| R9a | 모든 위키링크 형식 유효 | `bad-link` |
| R9b | 모든 위키링크 대상 실재 | `missing-target` |
| R9c | 자기 자신 가리키는 링크 없음 | `self-link` |
| R9d | `supersedes` 사이클 없음 | `cycle-supersedes` |
| R9e | `depends_on` 사이클 없음 | `cycle-depends_on` |
| R9f | `status` 값이 단계별 enum 안에 있는가 | `bad-status` |
| R10 | content/adr `role` 값이 enum 안에 있는가 (선택 필드 — 박혔을 때만) | `bad-role` |

## Warnings (차단 X, 안내만)

| # | 검사 | 코드 |
|---|------|------|
| W1 | idea/spec/adr 본문 ≤ 5000자 (frontmatter 제외) | `long-body` |

`long-body` 는 `_map.md` 재생성을 막지 않는다. stderr 로 경고만 출력. 한도는 `validate.py` 의 `BODY_LENGTH_LIMIT`.

## 검사 대상 필드

- `sources` — spec(idea-* 허용) / adr(spec-* 허용 — 메타 ADR / wiki-* 허용 — 콘텐츠 ADR)
- `related_to`, `supersedes`, `depends_on` — idea/spec/adr 모두 허용
- `status` enum:
  - idea: `open` (default) / `absorbed` / `archived` / `superseded` (선택 필드)
  - spec: `draft` / `active` / `accepted` / `deprecated` (필수)
  - adr: `proposed` / `accepted` / `superseded` / `deprecated` (필수, 메타·콘텐츠 공통)
  - inbox: `pending` / `promoted` / `archived` (선택)
  - sources: `pending` / `promoted` / `superseded` (선택)
  - wiki: `pending` / `promoted` / `superseded` (선택)
  - harness: `pending` / `released` (선택)
- `role` enum (R10, content/adr 만, 선택): `base|planner|pm|frontend|backend|qa|infra` ([[adr-0011-base-hoisting]] §1).
- `categories` — 자유 enum, 다중, 모든 type 의 선택 필드 ([[adr-0003-content-pipeline]] §categories).

## `docs/_map.md` 구조

```
# Docs Map
> 자동 생성. 수동 편집 금지.
_N spec(s), M idea(s), K adr(s), U unpromoted_

## Relations          ← 빠른 조회용 상단 배치
### supersedes
- [a] → [b]
### depends_on
- [a] → [b]
### related_to
- [a] ↔ [b]           (양방향, 1번만)

## Specs              ← topic→spec, sources 뷰
| Topic | Status | Spec | Sources | Scope |

## Ideas (lineage view)   ← idea→spec 역방향 인덱스
| File | Status | Absorbed into |

## ADRs                   ← spec→adr 결정 로그
| Status | Date | ADR | Source spec |
```

특이 표시:
- `⚠ multi-spec` — 한 idea 가 여러 spec 에 흡수됨 (이중 분기 가능성)
- 미승격 idea: `_(unpromoted)_`

## `content/_map.md` 구조

콘텐츠 5단 (`inbox / sources / wiki / adr / harness`) 자산 카운트 + status 분포 + categories facet 인덱싱. 자세한 명세는 ADR-0003 §자산 단위 / §status 라이프사이클 / §categories.

## When violations found

1. 코드별 1줄 요약으로 사용자 보고.
2. 자동 수정 제안:
   - `missing-target` → 오타 / 파일 복원
   - `cycle-*` → 순환 끊기 (어느 엣지를 제거할지 사용자 결정)
   - `dup-owns` → 둘 중 하나 deprecate 또는 병합
   - `self-link` → 해당 라인 제거
   - `bad-status` / `bad-role` → enum 표 참조해 정정
   - `bad-source-kind` → spec.sources 는 idea-*, adr.sources 는 spec-*/wiki-* 로 정정
3. 사용자 승인 → 수정 → 재검증.

## Don't

- `_map.md` 직접 편집 금지 — 자동 생성물.
- 위반 무시하고 머지 금지 — 단일 실패점 (`_map.md`·promote-docs·Obsidian 그래프 모두 멈춤).
- frontmatter 어휘 추가 시 ADR-0004 R 룰셋 갱신 필수.
