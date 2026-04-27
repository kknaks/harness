---
name: docs-validate
description: idea + spec 프론트매터 정합성을 검증하고 docs/_map.md (관계 그래프 + lineage 뷰)를 재생성한다. 새 idea/spec 작성 또는 관계 추가 직후 사용. PostToolUse 훅으로 docs/ 변경 시 자동 호출되기도 함.
---

# Docs Validate

`docs/_map.md` 는 모든 문서의 관계를 양방향으로 인덱싱한 자동 생성 뷰. 각 문서의 프론트매터가 SSOT.

## Checks

| # | 검사 | 위반 코드 |
|---|------|-----------|
| 1 | idea 필수 필드 (`id`, `type`) | `missing-frontmatter` |
| 2 | spec 필수 9개 필드 | `missing-frontmatter` |
| 3 | 프론트매터 자체가 없는 경우 | `no-frontmatter` |
| 4 | `type` 이 디렉토리와 일치 | `type-mismatch` |
| 5 | `id` 유일성 (전체) | `dup-id` |
| 6 | `owns` 유일성 (spec) | `dup-owns` |
| 7 | spec.sources 비어있지 않음 | `no-sources` |
| 8 | sources 항목이 idea-* 만 | `bad-source-kind` |
| 9 | 모든 위키링크 형식 유효 | `bad-link` |
| 10 | 모든 위키링크 대상 실재 | `missing-target` |
| 11 | 자기 자신 가리키는 링크 없음 | `self-link` |
| 12 | `supersedes` 사이클 없음 | `cycle-supersedes` |
| 13 | `depends_on` 사이클 없음 | `cycle-depends_on` |

검사 대상 필드:
- `sources` (spec only) — idea-* 만 허용
- `related_to`, `supersedes`, `depends_on` — idea/spec 모두 허용

## When to use

- `promote-idea-to-spec` 의 promote/merge 직후 (자동).
- `docs-naming/scripts/new-idea.sh` 직후.
- 관계 필드 직접 편집 후.
- 정기 점검.

## Output

- 통과 → stdout `OK: N spec(s), M idea(s) consistent. ...`, exit 0, **`docs/_map.md` 재생성**.
- 위반 → stderr 위반 목록, exit 1, **`_map.md` 미변경**.

리포트 예: `examples/validation-report.md`.

## `docs/_map.md` 구조

```
# Docs Map
> 자동 생성. 수동 편집 금지.
_2 spec(s), 5 idea(s), 1 unpromoted_

## Relations          ← 빠른 조회용 상단 배치
### supersedes
- [a] → [b]
### depends_on
- [a] → [b]
### related_to
- [a] ↔ [b]           (양방향, 1번만)

## Specs              ← topic→spec, sources 뷰
| Topic | Status | Spec | Sources |

## Ideas (lineage view)   ← idea→spec 역방향 인덱스
| File | Absorbed into |
```

특이 표시:
- `⚠ multi-spec` — 한 idea 가 여러 spec 에 흡수됨 (이중 분기 가능성)
- 미승격 idea: `_(unpromoted)_`

## Scripts

- `scripts/validate.sh` — 검증 + (성공 시) `_map.md` 재생성.

## Checklist

`checklist.md`.

## When violations found

1. 코드별 1줄 요약으로 사용자 보고.
2. 자동 수정 제안:
   - `missing-target` → 오타 / 파일 복원
   - `cycle-*` → 순환 끊기 (어느 엣지를 제거할지 사용자 결정)
   - `dup-owns` → 둘 중 하나 deprecate 또는 병합
   - `self-link` → 해당 라인 제거
3. 사용자 승인 → 수정 → 재검증.
