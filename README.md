# Harness

mediness 사내 하네스 시스템.

두 레이어를 한 repo 에서 운영한다.

- **메타 레이어** (`docs/`) — 하네스 자체의 의사결정. `idea → spec → adr` 3단.
- **콘텐츠 레이어** (`content/`) — 사내 지식·자산 파이프라인. `inbox → sources → wiki → adr → harness` 5단. 마지막 `harness/` 가 plugin 배포 monorepo.

## Structure

```
.
├── docs/             메타 (idea/ · spec/ · adr/ · _map.md)
├── content/          콘텐츠 (inbox/ · sources/ · wiki/ · adr/ · harness/)
├── .claude/skills/   메타 docs 작업 도구
└── CLAUDE.md         Claude 진입점
```

진입점:
- `docs/_map.md` — 메타 레이어 그래프 (자동 생성)
- `content/_map.md` — 콘텐츠 레이어 그래프 (자동 생성)
- `docs/adr/adr-0001-directory-structure.md` — 디렉토리 트리 SSOT

## Workflow

**메타** — 하네스 설계 변경:

```
idea  →  spec  →  adr
초안     조율중    확정
```

**콘텐츠** — 자산 정제·승격:

```
inbox  →  sources  →  wiki  →  adr  →  harness
원자료    1차정리     합성    결정    배포
```

각 단계는 `.claude/skills/promote-docs/` 의 `*-to-*.sh` 또는 `merge-*-to-*.sh` 로 승격/병합 (ADR-0012).

## Skills

- `docs-naming` — 파일명 규칙 + 새 idea 생성
- `promote-docs` — 단계 간 승격 + 병합
- `docs-validate` — 프론트매터·관계 검증 + `_map.md` 재생성

`docs/` 편집 시 `PostToolUse` 훅으로 `docs-validate` 자동 실행.

## Conventions

- 모든 idea/spec/adr 은 `id`, `type` 프론트매터 필수
- 관계 4종: `sources` (lineage), `related_to`, `supersedes`, `depends_on` — 모두 위키링크 리스트
- 각 spec 은 `owns: <topic>` 으로 SSOT 선언
- 자세한 규칙은 `.claude/skills/docs-naming/SKILL.md`
