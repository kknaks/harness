---
id: adr-0001
title: Directory Structure
type: adr
status: accepted
date: 2026-04-28
sources:
  - "[[spec-02-directory-structure]]"
tags: [adr]
aliases: []
---

# Directory Structure

## Context

mediness 는 두 개의 서로 다른 레이어를 동시에 운영해야 한다.

- **콘텐츠 레이어**: 5단 파이프라인(inbox → sources → wiki → adr → harness). 사내 지식·자산이 정제·승격되는 라인.
- **메타 레이어**: 하네스 프로젝트 자체에 대한 의사결정(idea → spec → adr).

두 레이어는 lifecycle, 권한, 외부 노출 표면, 갱신 주기 모두 다르다. 한 디렉토리 안에 섞으면:
- 인덱스(_map.md)가 비대해지고 의미가 흐려진다.
- 검증·승격 도구가 두 lifecycle 을 동시에 처리해야 해 결합이 늘어난다.
- 권한 정책(콘텐츠 inbox 만 공용 vs 메타 전부 메인테이너)이 디렉토리 단위로 매핑 안 된다.

또한 메타 레이어도 ADR 도입으로 idea → spec → adr 3단으로 확장한다 (콘텐츠 5단의 idea·wiki·adr 와 어휘 대칭).

## Decision

**메타와 콘텐츠를 형제 디렉토리로 분리, 각자 자기 `_map.md` 를 보유한다.** 본 ADR 이 mediness repo 디렉토리 트리의 SSOT.

### 전체 트리

```
{repo-root}/                          (mediness 사내 모노레포)
├── .claude/                          ← 메인테이너 측 (메타데이터 스킬)
│   └── skills/
│       ├── docs-naming/              \
│       ├── docs-validate/             ─ 메타 docs 작업 도구
│       ├── promote-docs/             /
│       └── scripts/
│           └── sanitize.sh           ← 공용 셸 헬퍼 (모든 메타 스킬이 source)
├── docs/                             ← 메타 (3단)
│   ├── _map.md
│   └── idea/ · spec/ · adr/
├── content/                          ← 콘텐츠 (5단)
│   ├── _map.md
│   ├── inbox/ · sources/ · wiki/ · adr/
│   └── harness/                      ← 5단 마지막 = distribution monorepo
│       ├── .claude-plugin/
│       │   └── marketplace.json      ← 모든 plugin 등록
│       └── plugins/
│           ├── base/                 ← 모든 역할 공통 (plugin 내부 표준 펼침 ▽)
│           │   ├── plugin.json       ← manifest (mcpServers, autoUpdate 등)
│           │   ├── skills/
│           │   │   └── <skill>/      ← e.g., harness, /medi:new
│           │   │       ├── SKILL.md
│           │   │       ├── scripts/  (선택)
│           │   │       └── examples/ (선택)
│           │   └── hooks/
│           │       └── hooks.json    ← H1·H4·H5 등 hook 선언
│           ├── planner/ · pm/        ← (동일 plugin 내부 표준)
│           ├── frontend/ · backend/  ← (동일 plugin 내부 표준)
│           └── qa/ · infra/          ← (동일 plugin 내부 표준)
├── CODEOWNERS                        ← 영역별 자동 리뷰어
├── CONTRIBUTING.md
└── .github/workflows/                ← CI 검증, 자동 릴리즈
```

### Plugin 슬러그 컨벤션

`base` + 6 role plugin 의 슬러그는 **사람 역할 명사** 기준 (`planner/pm/frontend/backend/qa/infra`). medi_docs 카테고리 슬러그 (`planning/plan/spec/...` — 자산 카테고리, [[adr-0008-medi-docs-scaffold]]) 와는 다른 차원이라 어휘 분리. [[adr-0003-content-pipeline]] 의 6 role 정의 (조직 구성원 역할) 를 reflect.

### Plugin 내부 표준

모든 plugin (`base/` + 6 role) 동일 패턴:
- `plugin.json` — manifest. `mcpServers`, hook 선언 진입, `autoUpdate` 등.
- `skills/<skill>/` — 사용자 배포본 스킬. 내부 구조는 [[adr-0007-skill-authoring-rules]] §1 (SKILL.md 필수, scripts/examples/checklist/reference 선택).
- `hooks/hooks.json` — hook entries. 첫 출시 hook 셋은 [[adr-0009-harness-hooks]] §1.

자산 배치·운영 정책 (어떤 자산이 어느 plugin 에 들어가는가, 왜) 은 별도 ADR — [[adr-0007-skill-authoring-rules]], [[adr-0009-harness-hooks]], [[adr-0010-harness-mcp]], [[adr-0011-base-hoisting]]. 본 ADR 은 트리 자체만 owns.

### `.claude/skills/` ↔ `<plugin>/skills/` 영역 분리

같은 repo 안 두 지붕 공존:
- `.claude/skills/` = **메인테이너 측 메타데이터 스킬** (현재 mediness repo 작업 도구. 메인테이너가 신뢰 기반으로 위험 명령 자유).
- `<plugin>/skills/` = **사용자 배포본 스킬** (사용자 환경에서 동작. 권한 엄격).

작성 형식·검증 룰은 동일, 권한 강도만 차등 — [[adr-0007-skill-authoring-rules]] §1.

### Role plugin 책임 예시 (확정 아님, 운영하며 형성)

| Plugin | 담는 것 (예시) |
|--------|----------------|
| `base` | 회사 CLAUDE.md, 시크릿 차단 훅, 커밋 컨벤션, 메타 도구 |
| `planner` | 기획서 템플릿, RFP, 시장 분석 |
| `pm` | 일정 추적, 회의록, 진행 보고 |
| `frontend` | React/Next/Vite 컨벤션, 컴포넌트, 디자인 토큰 |
| `backend` | API 설계, DB 마이그레이션, Python/PG 패턴 |
| `qa` | 테스트 시나리오, 회귀 체크, 결함 분류 |
| `infra` | 배포·CI/CD, k8s/Terraform, 시크릿 관리 |

### 부속 결정

- 두 `_map.md` 는 동일한 schema·format·검증 도구를 사용. `docs-validate` 가 두 루트를 각각 스캔해 두 인덱스를 독립 생성.
- 레이어 간 위키링크 참조는 원칙적으로 금지 (분리 유지).
- `harness/` 는 `content/` 안에 둔다 (배포 시 packaging 스크립트가 가져감). 레포 루트 노출 여부는 향후 별도 ADR 로 결정.
- `marketplace.json` 은 `content/harness/.claude-plugin/` 에 위치. 모든 plugin 의 등록 진입.

## Consequences

**Pros**
- 권한 정책이 디렉토리 단위로 깔끔히 매핑 (inbox 만 공용, 그 외 메인테이너).
- 두 레이어가 독립적으로 진화 가능 — 콘텐츠 도입이 메타 도구(`docs-validate` 등) 에 영향 없음.
- 사용자(plugin 소비자) 시야가 `harness/` 로 한정되어 노출 표면 단순.
- ADR 도입으로 메타·콘텐츠 어휘가 대칭 — 도구·관계 규칙 재사용성 ↑.

**Cons**
- `_map.md` 가 두 개 — 작업 시 두 인덱스를 봐야 함.
- `docs-validate` 가 두 루트 스캔하도록 확장 필요 (현재는 메타만 — 콘텐츠 운영 시작 시 일반화).
- 레이어 간 참조 금지 원칙이 실무에서 흐려질 위험 (예: 메타 idea 가 콘텐츠 wiki 를 참조하고 싶을 때).

**Follow-ups**
- 콘텐츠 레이어 가동 시 `docs-validate` 를 양쪽 루트 스캔하도록 확장.
- `harness/` 분리 노출 여부 결정 (별도 ADR).
- 레이어 간 참조가 정말 필요한 경우가 생기면 그때 별도 ADR 로 예외 규약 추가.

## Notes

- 2026-04-28: status proposed → accepted. source spec-02 status → accepted (통째 흡수 패턴).
- 2026-04-29: 정합성 검증 후 spec-02 의 트리·Plugin 슬러그 컨벤션·Plugin 내부 표준·영역 분리·Role plugin 책임 예시·marketplace.json 부속결정을 본 ADR 본문으로 흡수. spec-02 는 lineage stub 으로 축소 (status accepted 정합화). 이전엔 spec-02 가 살아있는 SSOT 로 운영되었으나 [[adr-0003-content-pipeline]] §관계 규칙 (수직 단방향 승격) 위반 — 결정 SSOT 는 흡수 ADR 가 가짐.
- 2026-04-30: marketplace.json 위치 정정 (v0.1 dogfood). `content/harness/.claude-plugin/marketplace.json` → `.claude-plugin/marketplace.json` (repo root). Claude Code 의 plugin marketplace 컨벤션이 `.claude-plugin/marketplace.json` 을 *repo root* 에서 찾으므로 `claude plugin marketplace add github:<repo>` 로 install 하려면 root 위치가 필수. source 경로는 `./plugins/<n>` → `./content/harness/plugins/<n>` 로 갱신. 5단 파이프라인 (`content/harness/` 가 distribution 단계) 구조는 보존 — repo root 의 marketplace.json 은 *distribution descriptor* (어디서 plugin 자산을 찾는지) 만 박힘. v0.1 release 의 origin 은 임시로 `kknaks/harness` (사내 mediness 배포 전), v1.0 cutover 시점에 정식 origin 결정 (base/README.md §사용자 흐름 박제).
- 2026-04-30 (II): **§부속결정 의 7-plugin marketplace 결정 supersede** — [[adr-0014-single-plugin-scaffolder]] 채택. dogfood 시점에 사용자 마찰 두 건 (install 7번 / 팀 공유 부재) 발견 → 단일 plugin (`harness`) + `/harness init <role>` scaffolder 모델로 전환. role 별 SKILL 자산은 plugin 내부 `role-templates/<role>/skills/...` 비활성 영역에 박힌 후 사용자가 `init` 호출 시 *프로젝트의 `.claude/skills/`* 로 복사. marketplace.json 이 `harness-base + 6 role` 7 entry → `harness` 1 entry 로 축소. 본 ADR 의 *디렉토리 구조* (5 영역 / role plugin 디렉토리 구획) 결정은 살아있음 — 무엇이 어디 들어가는지의 *논리적 분리* 는 그대로 (단지 plugin 단위로 분할 install 하지 않을 뿐, role-templates 디렉토리로 분리는 유지). ADR-0005 autoUpdate / ADR-0011 base hoisting 도 의미 갱신 — Notes 박을 follow-up.

