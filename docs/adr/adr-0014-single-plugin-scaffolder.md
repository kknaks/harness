---
id: adr-0014
title: Single Plugin Scaffolder Distribution
type: adr
status: accepted
date: 2026-04-30
sources:
  - "[[spec-02-directory-structure]]"
  - "[[spec-09-version-rollout]]"
tags: [adr]
supersedes: []
related_to:
  - "[[adr-0001-directory-structure]]"
  - "[[adr-0005-version-rollout]]"
  - "[[adr-0008-medi-docs-scaffold]]"
  - "[[adr-0011-base-hoisting]]"
depends_on:
  - "[[adr-0007-skill-authoring-rules]]"
aliases: []
---

# Single Plugin Scaffolder Distribution

## Context

ADR-0001 §부속결정 가 채택한 *7-plugin 모델* (`harness-base` + 6 role plugin: planner/pm/frontend/backend/qa/infra) 을 사용자 입장에서 dogfood 한 결과 두 가지 마찰:

1. **install 절차 복잡** — 사용자는 `/plugin install harness-base` + 필요 role 마다 `/plugin install harness-<role>` 를 반복. "왜 7개 깔아야 해?" 혼란.
2. **자산 위치 불일치** — Claude Code plugin 모델은 `~/.claude/plugins/` 에 *전역* 설치. SKILL 본문은 사용자 프로젝트의 git 에 들어가지 않음 → *팀 공유 / 프로젝트별 커스텀* 가치 0. 사용자 멘탈 모델은 "프로젝트의 `.claude/skills/` 에 박힘 + git commit" 이었음.

7-plugin install-time-role-selection 모델은 *Claude Code 플러그인 메커니즘이 자연스럽게 제공하는 방향* 이지만, mediness 의 *팀 단위 커밋 가능한 SKILL 자산* 요구와 어긋남.

## Decision

**단일 plugin (`harness`) + `/harness init <role>` scaffolder 모델** 채택.

1. **단일 plugin 등록** — `marketplace.json` 에 `harness` 1개. 사용자는 `/plugin install harness` 한 번만.
2. **role 자산 = 비활성 템플릿** — 6 role 의 SKILL 자산은 plugin 내부 `role-templates/<role>/skills/...` 에 박힘. 이 위치는 Claude Code 의 SKILL 자동 활성 영역 *밖* — plugin install 직후엔 비활성 상태.
3. **`/harness init <role> [role...] [--force]`** — 본 SKILL 의 scaffolder 가 `role-templates/<role>/skills/*` 를 *현재 프로젝트의* `.claude/skills/<n>/` 로 복사. 복사 후 Claude Code 가 *프로젝트 로컬 SKILL* 로 인식 → 호출 가능.
4. **사용자 커스텀 보존** — 기본은 *기존 `.claude/skills/<n>/` 가 있으면 skip*. `--force` 시에만 덮어쓰기. 사용자 SKILL 본문 수정은 git 으로 추적 — 갱신 시 사용자 책임으로 머지.
5. **medi_docs scaffold 통합** — 처음 `init` 시 `scripts/scaffold-medi-docs.sh` 가 함께 호출되어 9 카테고리 박힘 ([[adr-0008-medi-docs-scaffold]] §4 흡수).

배포 메커니즘 비교:

| 차원 | plugin marketplace (구) | 단일 + scaffolder (본 ADR) |
|------|-------------------------|---------------------------|
| install 단위 | 7 plugin (base + 6 role) | 1 plugin (`harness`) |
| 자산 위치 | `~/.claude/plugins/<name>/` 전역 | `<project>/.claude/skills/<n>/` 프로젝트별 |
| role 선택 | install 시점 (`claude plugin install harness-<role>`) | `init` 시점 (`/harness init <role>`) |
| 갱신 | autoUpdate (plugin 자동) | `/harness init <role> --force` (사용자 수동) |
| 팀 공유 | X (사용자별 독립 install) | ✓ (`.claude/` git commit) |
| 프로젝트별 커스텀 | X (autoUpdate 가 덮어씀) | ✓ (skip 기본, force 만 덮어씀) |

## Alternatives Considered

| 후보 | 채택 안 한 이유 |
|------|------------------|
| 7-plugin 유지 + role 선택 install (ADR-0001 원안) | 팀 공유 / 프로젝트별 커스텀 두 핵심 가치 부재. dogfood 마찰 확인됨 |
| 별도 CLI 도구 (`harness init` 외부 명령) — `pip install harness-cli` 등 | 사용자 머신에 추가 의존성. plugin 만으로 충분 — `/harness` slash command 가 같은 역할. 배포·업데이트 채널 이중화 회피 |
| 단일 plugin 안에 *모든 role 의 SKILL 을 활성으로* 박기 | role 무관하게 모든 SKILL 이 *모든 프로젝트* 에서 활성 — 의도적 분리 (backend 프로젝트엔 frontend SKILL 없어도 됨) 무효화 |
| 단일 plugin + 사용자가 직접 `cp` (scaffolder 없음) | 사용자가 plugin 내부 경로 (`~/.claude/plugins/harness/role-templates/...`) 를 알아야 함 + 디렉토리 구조 유지 책임. 마찰 ↑ |
| ADR-0001 § 부속결정 의 7-plugin 결정만 supersede + role-templates 디렉토리는 ADR-0001 본문에 박기 | ADR-0001 의 *디렉토리 구조* 결정과 *배포 메커니즘* 결정이 한 ADR 에 묶여 결정 단위 비대. 분리해서 별 ADR 가 명료 |

## Implementation Path

| Action | 누가 | 언제 | 의존 / 산출 |
|--------|------|------|--------------|
| `content/harness/plugins/<role>/skills/*` → `content/harness/plugins/base/role-templates/<role>/skills/*` 이동 | 메인테이너 | v0.1 dogfood pivot | 기존 backend 자산 보존 |
| 6 role plugin 디렉토리 (`backend/frontend/...`) 삭제 — 단일 plugin 만 남김 | 메인테이너 | 동시 | `marketplace.json` 단일 entry |
| `marketplace.json` plugins 배열 7 → 1 | 메인테이너 | 동시 | install 명령 단일화 |
| `base/plugin.json` name `harness-base` → `harness` + version `0.1.0` | 메인테이너 | 동시 | install 명령 = `/plugin install harness` |
| `base/skills/harness/scripts/init.sh` 신설 — role-templates → `<project>/.claude/` 복사 | 메인테이너 | 동시 | 기본 skip / `--force` 덮어쓰기 |
| `base/scripts/scaffold-medi-docs.sh` 신설 (지금까지 plan 만 박혀있음) — 9 카테고리 idempotent | 메인테이너 | 동시 | `init.sh` 가 호출 |
| `base/role-templates/README.md` — 사용 가능 role + 호출 예시 | 메인테이너 | 동시 | 사용자 가시성 |
| 사용자 배포본 `update`·`uninstall` sub-command | 메인테이너 | v0.2 | 현재는 `init <role> --force` 가 update 역할 |
| 세밀한 sync (보편 슬롯만 갱신, 사용자 § 보존) — sync-skill 패턴 차용 | 메인테이너 | v0.2 | 사용자 커스텀 § 와 메인테이너 갱신 충돌 시 자동 머지 |

## Consequences

**Pros**
- Install 절차 1단계 (`/plugin install harness` 끝). role 선택은 *사용 시점* 으로 이동 → 자연.
- SKILL 자산이 프로젝트의 `.claude/skills/` 에 들어감 → git commit / 팀 공유 / 프로젝트별 커스텀 모두 자연.
- ADR-0008 medi-docs-scaffold 의 패턴 (cwd 박기 + idempotent) 을 SKILL 자산까지 확장 — 일관 모델.
- Claude Code 의 plugin 메커니즘 (autoUpdate / install 채널) 은 *plugin 자체* 갱신엔 그대로 활용. *복사된 SKILL 갱신* 만 사용자 수동.

**Cons**
- 사용자가 *프로젝트마다* `/harness init` 호출해야 함 (전역 install 1회면 끝나는 7-plugin 대비 마찰). 단, 새 프로젝트 셋업은 빈도가 낮음.
- 사용자 커스텀 보존이 *git 기반* — 메인테이너 갱신 받을 때 머지 충돌 가능 (사용자 책임). v0.2 의 sync-skill 패턴 차용까지는 임시 마찰.
- plugin 내부 `role-templates/` 가 Claude Code 자동 활성 영역 밖 — *비활성 영역* 이라는 사실을 README 와 ADR 로 명시해야 사용자/메인테이너가 혼동 안 함.
- 기존 7-plugin 모델 가정의 ADR (ADR-0001 §부속결정, ADR-0005 autoUpdate 의 *role plugin 갱신* 부분) 을 supersede / 갱신해야 정합.

**Follow-ups**
- [ ] ADR-0001 §부속결정 marketplace.json 의 7-plugin 박제 → 본 ADR 로 supersede 명시 + ADR-0001 Notes 박기
- [ ] ADR-0005 autoUpdate 의 *role plugin* 부분 — 단일 plugin 모델에선 plugin 자체 자동 갱신만 유효. *복사된 SKILL* 은 사용자 수동. ADR-0005 Notes 갱신
- [ ] ADR-0011 base hoisting — 단일 plugin 모델에선 *모든* 자산이 base plugin 안. "base 로 hoist" 의 의미는 *어느 role-templates/<role>/ 에 박을지 vs base 본체에 박을지* 로 변경. ADR-0011 Notes 갱신
- [ ] sync-skill 패턴을 사용자 .claude/ 에도 차용 (v0.2) — 갱신 시 보편 슬롯만 동기, 사용자 § 보존
- [ ] `/harness update` / `/harness uninstall` sub-command (v0.2)
- [ ] role-templates 가 frontend / planner / pm / qa / infra 로 누적 (v0.2+, 운영 사례 따라)

## Notes

- 2026-04-30 — accepted (dogfood pivot). 7-plugin → 1-plugin scaffolder 결정. v0.1 install 절차 검증 후 발견된 마찰 두 건 (install 복잡성 / 팀 공유 부재) 해소. 자매 ADR-0001 §부속결정 supersede 박기 위해 ADR-0001 Notes 갱신 필요. spec-02 distribution 은 이미 ADR-0001 에 흡수되어 있으나 본 결정의 sources 로 다시 박는 이유: ADR-0001 의 결정 단위 분리 (디렉토리 구조 vs 배포 메커니즘). 본 ADR 가 *배포 메커니즘* 결정 단위로 독립.
- 2026-04-30 (II): **dogfood install 시 학습 — Claude Code 의 SKILL ≠ slash command**. install + reload 후 `/harness` 호출 시 `Unknown command: /harness` 발생. 원인: `skills/<n>/SKILL.md` 와 `commands/<n>.md` 는 *별 메커니즘*. SKILL = description-매칭 (자연어 호출 시 활성). slash command = `commands/<n>.md` 박혀 있어야 `/<plugin-name>:<command-name>` 으로 호출 가능. *plugin 의 SKILL 이름이 자동 slash command 가 되지 않음.* 해결: `commands/init.md` + `commands/status.md` 박음 → `/harness:init backend` / `/harness:status` 형태 호출 가능. namespace 는 `<plugin-name>:<command-name>` 강제 — 단일 `/harness` 호출은 불가, 항상 namespace 동반. 메인테이너가 새 plugin 박을 때 잊지 말 것 — SKILL 만 박으면 자연어로만 호출 가능, slash command 까지 원하면 commands/ 도 박는다.
- 2026-04-30 (III): **role manifest 도입** — role-templates/<role>/role.json (`role` / `version` / `description` / `skills[]` / `commands[]` / `hooks[]` / `depends_on[]`). 이전엔 init.sh 가 `skills/*` 디렉토리 전체를 implicit 복사 → 어떤 skill 이 어떤 role 에 속하는지 *코드 외부에서 명시 불가*. manifest = SSOT — init.sh 가 manifest 의 skills[] 만 복사하고 실재 안 하면 exit 3 (메인테이너 갱신 누락 검증). manifest 부재 시 기존 implicit 동작 fallback (마이그레이션 호환). 새 role 추가 시 `role.json` 박는 게 표준. status command 도 manifest 의 description / skills 을 표시 → 사용자 가시성 ↑. role-templates/README.md §스키마 박혀 있음.
