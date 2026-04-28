# Harness

사내 하네스 시스템 프로젝트.

## Overview

(작성 예정)

## Structure

- `docs/idea/` — 초기 아이디어 및 브레인스토밍
- `docs/spec/` — 조율 중 제안 (idea 에서 발전, status 로 진행)
- `docs/adr/` — 확정 결정 (ADR, atomic, supersedes 체인)
- `.claude/skills/` — 프로젝트 전용 스킬

워크플로우: `idea` → `spec` → `adr`

## Conventions

- 문서 파일명 규칙: `.claude/skills/docs-naming/SKILL.md`

## Docs Entry Point

- `docs/_map.md` — Claude 의 문서 구조 진입점. **자동 생성, 수동 편집 금지**. 재생성은 `docs-validate`.
- 모든 idea/spec/adr 은 최소 `id`, `type` 프론트매터 필수.
- 관계 4종 (모두 위키링크 리스트): `sources` (spec→idea, adr→spec lineage), `related_to`, `supersedes`, `depends_on`.
- SSOT: 각 spec 의 `owns: <topic>` 선언.

## Skills

- `docs-naming` — 파일명 규칙 + 새 idea 생성 (`scripts/new-idea.sh`).
- `promote-docs` — 단계 간 승격 (`idea-to-spec.sh`, `spec-to-adr.sh`) + 기존 spec 에 idea 병합 (`merge.sh`).
- `docs-validate` — 프론트매터 + 관계 정합성 검증 + `_map.md` 재생성.

## Agents

- `idea-triage` — 20+ idea 누적 시 클러스터/중복/분기 후보 보고 (read-only).
- `spec-drafter` — promote/merge 직후 spec 본문 (Goal/Design/...) 을 sources idea 에서 합성.

## Hooks

- `PostToolUse` (Write|Edit) → `docs/idea/` 또는 `docs/spec/` 변경 시 `docs-validate` 자동 실행.
