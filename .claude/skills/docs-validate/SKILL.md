---
name: docs-validate
description: idea + spec + adr 프론트매터 정합성을 검증하고 docs/_map.md (관계 그래프 + lineage 뷰) + content/_map.md (5단 자산 + categories) 를 재생성한다. 새 idea/spec/adr 작성 또는 관계 추가 직후 사용. PostToolUse 훅으로 docs/ 변경 시 자동 호출되기도 함.
---

# Docs Validate

`docs/_map.md` / `content/_map.md` 는 모든 문서·자산 관계를 양방향으로 인덱싱한 자동 생성 뷰. 각 문서의 프론트매터가 SSOT.

## When to use

- `promote-docs` 의 promote/merge 직후 (자동).
- `docs-naming/scripts/new-idea.sh` 직후.
- 관계 필드 (`sources`/`related_to`/`supersedes`/`depends_on`) 또는 `role`/`categories`/`status` 직접 편집 후.
- 정기 점검.

## How to invoke

`scripts/validate.sh` — 검증 + (성공 시) `_map.md` 재생성.

## Output

- 통과 → stdout `OK: N spec(s), M idea(s), K adr(s) consistent. ...`, exit 0, **`docs/_map.md` + `content/_map.md` 재생성**.
- 위반 → stderr 위반 목록, exit 1, **`_map.md` 미변경**.
- 경고 → stderr `WARNINGS:`, 차단 X (예: `long-body`).

## 검증 항목 요약

- 필수 frontmatter 필드 (idea/spec/adr 단계별)
- 위키링크 무결성 (형식·실재·자기참조 X)
- 그래프 사이클 (`supersedes`/`depends_on`)
- 단계별 enum (`status`, `role`)
- 본문 길이 경고 (`long-body`)

자세한 검사 룰셋·코드·enum 정의·`_map.md` 구조·위반 시 수정 절차는 [`rules.md`](rules.md).

## 보안 고려사항

- 읽기 전용 검증. 파일 수정은 `_map.md` 재생성만 (idempotent).
- `allow_commands` 필요 X (Python 실행 + read/write `_map.md`).
- `_map.md` 직접 편집 금지 — 자동 생성물 (`rules.md` §Don't).
