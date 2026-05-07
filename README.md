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

## Installation

Claude Code 가 설치되어 있어야 한다.

### 1. Marketplace 등록

```
/plugin marketplace add kknaks/harness
```

(또는 fork / 사내 미러 URL)

### 2. Plugin 설치

```
/plugin install harness@harness
```

`harness` plugin 이 `~/.claude/plugins/` 에 박힘. 이 단계에서는 SKILL 비활성 — `role-templates/` 안에 *템플릿* 으로만 존재 (ADR-0014).

### 3. Role 자산 scaffold (사용처 프로젝트마다)

프로젝트 루트로 이동 후:

```
/harness init backend
```

이 명령이 plugin 의 `role-templates/backend/skills/*` 를 *프로젝트의* `.claude/skills/<name>/` 로 복사. 복사된 SKILL 은 *프로젝트 로컬* 이라 Claude Code 가 자동 활성 + git commit 가능.

지원 role: `base / planner / pm / frontend / backend / qa / infra / fullstack`

```
/harness init backend             # 단일 role
/harness init backend qa          # 여러 role 동시
/harness init backend --force     # 기존 .claude/skills 덮어쓰기 (사용자 커스텀 잃음)
```

기본은 *기존 SKILL 보존* (skip). 갱신 받고 싶으면 `--force`.

### Backend role 박히는 자산 (참고)

```
.claude/skills/
├── api-design/          (엔드포인트 설계)
├── code-review/         (사후 PR 검토)
├── tdd-cycle/           (Red→Green→Refactor)
├── refactor-layered/    (4계층 정렬)
├── test-design/         (테스트 설계)
├── entity-add/          (Model→Alembic→Schema→Repo→Test 5단)
├── alembic-migration/   (autogenerate / forward-only / conflict)
└── db-transaction/      (reference — ACID/격리/refresh=False 함정)
```

`db-transaction` 은 `asset_type: reference` (ADR-0015) — 절차 SKILL 아님, 자매 SKILL 본문에서 link 로 lookup.

### 갱신

```
/plugin update harness        # plugin 자체 갱신 (role-templates 새 버전 받음)
/harness init backend --force # 프로젝트의 .claude/skills 갱신 (기존 사용자 커스텀 덮어씀)
```

### 제거

```
/plugin uninstall harness
```

`medi_docs/` 같은 사용자 자산은 보존 (ADR-0008). 프로젝트의 `.claude/skills/` 는 사용자 손으로 정리.

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
