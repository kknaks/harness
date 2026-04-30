---
name: docs-naming
description: docs/ + content/ 하위 문서의 파일명 + 프론트매터 규칙. 새 idea 만들 때, 또는 파일명/스키마를 점검할 때 사용.
---

# Docs Naming & Authoring

`docs/` + `content/` 하위 모든 문서는 (1) 파일명 규칙, (2) 최소 프론트매터, 둘 다 따른다.

## When to use

- 사용자가 "새 idea 만들어줘" / "이 메모 idea 로" 같은 요청 시 → `new-idea.sh` 호출.
- 파일명 / 프론트매터 스키마 점검 / 기존 자산 정리 시 → [`rules.md`](rules.md) 참조.
- 단계 간 승격은 본 스킬 X — `promote-docs` 사용.

## How to invoke

`scripts/new-idea.sh "<title>"` — 다음 NN 산정 + frontmatter 포함 idea 파일 생성 + 경로 출력.

후속:
1. 본문에 사용자가 준 메모 작성
2. 관계 (`related_to`/`supersedes`/`depends_on`) 가 있으면 frontmatter 에 추가
3. `docs-validate/scripts/validate.sh` 로 검증 (PostToolUse 훅이 자동 호출하기도 함)

spec / ADR 생성은 `promote-docs` 사용.

## 핵심 룰 요약

```
{type}-{NN}-{title}.md      (idea / spec / sources / wiki / harness — NN 2자리)
adr-{NNNN}-{title}.md       (adr — 4자리, 메타·콘텐츠 카운터 분리)
```

- `{title}` = kebab-case
- 번호 재사용 금지, 디렉토리별 독립, 단계 간 일치 X
- frontmatter 최소 `id` + `type` 필수

자세한 룰셋·type별 frontmatter 스키마·status enum·예시·금지 사항은 [`rules.md`](rules.md).

## 보안 고려사항

- `new-idea.sh` 는 `<title>` 입력을 sanitize (kebab-case 검증) 후 파일 생성. 경로 탈출 방지.
- `allow_commands` 필요 X (read/write 만).
