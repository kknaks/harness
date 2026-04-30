---
id: adr-0008
title: Medi Docs Scaffold
type: adr
status: accepted
date: 2026-04-29
sources:
  - "[[spec-10-medi-docs-scaffold]]"
tags: [adr]
aliases: []
depends_on:
  - "[[adr-0006-onboarding-skill]]"
  - "[[adr-0001-directory-structure]]"
related_to:
  - "[[adr-0004-frontmatter-naming]]"
---

# Medi Docs Scaffold

## Context

(승격 원본: `docs/spec/spec-10-medi-docs-scaffold.md`)

mediness harness plugin 의 핵심 가치 제안 = **"플러그인 깔면 사용자 프로젝트에 정형화된 문서 구조가 자동으로 만들어진다"**. 코드 자동화 스킬만 제공하면 반쪽 — 의사결정·정책·기획을 쌓을 표준 자리가 없으면:

- 매 프로젝트마다 사람·Claude 가 docs 구조를 새로 학습 → 학습 비용 ↑
- 6 role (기획·PM·프론트·백엔드·QA·인프라) 이 어디에 무엇을 쓰는지 합의 부재 → 산출물이 흩어짐
- 시점의 정책 스냅샷 추적 불가 ("v1.0 출시 시점에 정책이 뭐였지?" 답 X)

이 ADR 은 사용자 프로젝트에 `medi_docs/` 를 자동 scaffold 해 위 3가지를 동시에 해결한다.

레이어 구분:

| 레이어 | 위치 | 누가 만지나 | 무엇 |
|--------|------|-------------|------|
| harness 메타 | (harness repo) `docs/idea` `docs/spec` `docs/adr` | harness 메인테이너 | harness 자체 의사결정 |
| harness 콘텐츠 | (harness repo) `content/inbox` … `content/harness` | harness 메인테이너 | 5단 파이프라인 |
| **유저 medi_docs** | (user repo) `medi_docs/current/` + `v{label}/` | 유저 팀 (6 role) | 유저 프로젝트의 9 카테고리 산출물 |

세 레이어 모두 같은 frontmatter 어휘 ([[adr-0004-frontmatter-naming]] 의 R4-R9) 와 관계 4종을 공유하지만 `_map.md` 는 분리. medi_docs 는 사용자 자산이라 [[adr-0006-onboarding-skill]] 의 *처음 셋업* 분기에서 의도 파악 후 lazy 생성한다 (install hook 강제 X — 사용자 통제권 보존).

## Decision

### 1. 9 카테고리 풀셋 (개발 사이클 전체 커버)

```
<user-project>/
└── medi_docs/
    ├── current/                  # 살아있는 작업 상태 (carry-forward)
    │   ├── planning/             # 기획·요구사항·RFP — "무엇을"
    │   ├── plan/                 # 마일스톤·스프린트·일정 — "언제·어떻게"
    │   ├── spec/                 # 기술 명세 (API, 컴포넌트, 시스템)
    │   ├── policy/               # 도메인 정책·비즈니스 규칙
    │   ├── adr/                  # 결정 로그 (atomic)
    │   ├── runbook/              # 운영 절차·배포 가이드
    │   ├── test/                 # 테스트 시나리오·회귀
    │   ├── release-notes/        # 변경 이력 (사용자용)
    │   ├── retrospective/        # 회고·포스트모템
    │   └── _map.md               # auto (관계 그래프)
    ├── v1.0/                     # cut 시점 박제 (read-only)
    │   └── ... + _map.md         # 박제된 그래프
    └── v0.9/
```

각 카테고리: `README.md` (1-screen 안내) + `template.md` (frontmatter + 본문 스켈레톤) + 실제 문서들. 카테고리별 구체 스키마는 [[spec-11-medi-docs-frontmatter]].

**사이클 매핑**: `planning → plan → spec/policy → adr → 구현 → test → release-notes → runbook → retrospective`.

### 2. `current/` + `v{label}/` 버전 모델 (carry-forward)

| 시점 | `current/` | `v{label}/` |
|------|-----------|--------------|
| t0 scaffold | 빈 9 카테고리 + README/template | 없음 |
| t1 작업 중 | spec-01-foo.md 생성 | 없음 |
| t2 v1.0 cut | (그대로 유지) | v1.0/ = t1 스냅샷 박제 |
| t3 후속 작업 | spec-01-foo.md 수정 | v1.0/ 그대로 (read-only) |
| t4 v1.1 cut | (그대로 유지) | v1.1/ = t3 스냅샷 |

**carry-forward 의도**: `current/` = 살아있는 incremental 작업 상태, `v{label}/` = 박제된 시점 스냅샷. `diff -r v1.0/ v1.1/` 로 자연스러운 정책 변화 추적.

### 3. cut 동작

- **트리거**: 수동 skill 호출 (`/medi:version-cut`). git tag 자동 연동 X (사용자 git workflow 침범 회피).
- **버전 라벨**: 사용자 자유 지정 (`v1.0`, `2026Q2`, `release-2026-04` 등). semver 강제 X.
- **검증 강제**: cut 직전 `docs-validate` 통과 필수. 실패 시 박제 차단. `--force` 옵션은 운영 후 결정.
- **박제 범위**: `current/` 전체 → `v{label}/` 으로 복사. `_map.md` 도 함께 박제.
- **carry-forward**: cut 후 `current/` 그대로 유지.
- **read-only**: `v{label}/` 는 cut 이후 수정 X. 변경 필요 시 새 cut.

### 4. scaffold 시점

[[adr-0006-onboarding-skill]] 의 *처음 셋업* 분기에 통합:

1. 사용자가 `harness` skill 호출 → 현재 상태 확인
2. `medi_docs/` 부재 + 처음 셋업 분기 → dry-run: "medi_docs/current/ 9 카테고리 생성 + README/template 동봉. 진행?"
3. 사용자 동의 → scaffold 동작
4. 이미 `medi_docs/` 존재 → no-op (기존 자산 보호)

install hook 강제 X — 사용자 통제권 보존. `harness` skill 의 idempotent + dry-run 원칙 적용.

### 5. uninstall 처리

- plugin uninstall 시 `medi_docs/` **남김** — 콘텐츠는 사용자 자산.
- uninstall 안내 메시지: "medi_docs/ 는 사용자 자산이라 보존됩니다. 필요 시 직접 삭제하세요."

### 6. 강제 룰 (D1-D4)

| 룰 | 검증 대상 | 위반 시 |
|----|-----------|---------|
| **D1** cut 직전 검증 | `current/` 전체가 [[adr-0004-frontmatter-naming]] R4-R9 통과 | **차단** (cut 불가) |
| **D2** `v{label}/` 불변 | 박제된 `v{label}/` 가 git history 상 머지 후 수정 | **경고** (의도된 정정인 경우 메인테이너 판단; 권장은 새 cut) |
| **D3** 카테고리 디렉토리 일관성 | `medi_docs/current/` + 모든 `v{label}/` 가 9 카테고리 동일 보유 | **경고** (사용자가 의도적으로 카테고리 추가 시 본인 책임) |
| **D4** lineage 필수 | §7 의 진실 흐름 — 모든 비-planning 문서가 `sources:` 최소 1개 보유 (retrospective 만 다수 cross-cutting) | **차단** (`docs-validate` 실패) |

`docs-validate` 가 multi-target 으로 사용자 medi_docs/ 도 검증 (메인테이너 도구와 별개 산출물; [[spec-12-medi-docs-tooling]] 에서 사용자 배포본 명세).

### 7. 진입점·lineage 위계

medi_docs 의 단일 진실 진입점은 `planning/` (최상위 진실 — *왜·무엇을*). `plan/` 은 planning 의 파생 진실 (*어떻게·언제*). 디렉토리는 §1 의 9 카테고리 flat 그대로 유지하고, 위계는 frontmatter `sources:` ([[adr-0004-frontmatter-naming]] 의 관계 4종 어휘) 로만 표현한다.

**진실 흐름**

```
planning/                                       (root)
  ├─ policy/*       sources: [[planning/...]]
  └─ plan/*         sources: [[planning/...]]
        ├─ spec/*           sources: [[plan/...]]
        ├─ adr/*            sources: [[spec/...]] 또는 [[plan/...]]
        ├─ test/*           sources: [[spec/...]]
        ├─ runbook/*        sources: [[spec/...]]
        └─ release-notes/*  sources: [[plan/...]]   (cut 시점 산출)

retrospective/*   sources: 다수 cross-cutting (planning/plan/spec 등)
```

**원칙**

- *planning 은 root* — `sources:` 비어있거나 외부 (비전·RFP 등) 만 가리킬 수 있음.
- *비-planning 문서는 `sources:` 최소 1개 필수*. retrospective 만 다수 cross-cutting.
- *위계는 frontmatter 로만* — 카테고리 디렉토리는 §1 그대로 평면, 위계 깊이는 `sources:` 그래프로 표현.
- *진입점 1개* — Claude·사용자가 medi_docs 들어올 때 `planning/` 부터 읽고 `sources:` 그래프 따라 내려감. `_map.md` 가 이 트리를 시각화.

강제 룰은 §6 의 **D4**.

## Alternatives Considered

| 후보 | 채택 안 한 이유 |
|------|------------------|
| 카테고리 3개만 (`spec`/`policy`/`planning`) | 개발 사이클 전체 안 커버. test/runbook/retrospective 등 소실 |
| 카테고리 자유 (사용자가 정의) | 정형화 가치 ↓. Claude 가 매 프로젝트 재학습 |
| **9 카테고리 풀셋 (현재 ✓)** | 사이클 전체 커버 + 표준화 |
| `docs/` 디렉토리 사용 (별도 네임스페이스 X) | 사용자가 이미 docs/ 가지는 경우 충돌. `medi_docs/` 가 안전 |
| 단일 디렉토리 (current 만, 버전 X) | 시점 스냅샷 X — "v1.0 시점 정책" 추적 불가 |
| reset 모델 (cut 후 current 비움) | 누적 작업 모델과 어긋남. 매 사이클 0 부터 시작 부담 |
| **carry-forward (현재 ✓)** | 살아있는 작업 + 시점 박제 둘 다 |
| install hook 강제 scaffold | 사용자 통제권 침범. plugin 설치 = medi_docs 강제 → 거부감 |
| `harness` skill lazy scaffold (현재 ✓) | 의도 파악 후 생성. 사용자 동의 기반 |
| git tag 자동 cut | 사용자 git workflow 침범. 모든 tag 가 medi_docs cut 의도 X |
| **수동 skill cut (현재 ✓)** | 사용자 명시 호출. 단순 |
| uninstall 시 medi_docs 삭제 | 사용자 자산 손실 위험. 디렉토리 남김 + 안내가 안전 |

## Implementation Path

| Action | 누가 | 언제 | 의존 / 산출 |
|--------|------|------|--------------|
| `harness` skill 의 *처음 셋업* 분기에 medi_docs scaffold 로직 추가 | 메인테이너 | v0.1 release 전 | [[adr-0006-onboarding-skill]] |
| 9 카테고리 README + template scaffold 자산 (base plugin 안 동봉) | 메인테이너 | v0.1 release 전 | [[spec-11-medi-docs-frontmatter]] template 구체 |
| `/medi:version-cut` skill 작성 (D1-D3 룰 적용) | 메인테이너 | v0.1 release 전 | [[spec-12-medi-docs-tooling]] |
| `docs-validate` 사용자 배포본 (D1-D4 + R4-R9 multi-target) | 메인테이너 도구 | v0.1 release 전 | base plugin 안 별도 산출물 |
| uninstall 안내 메시지 작성 | 메인테이너 | v0.1 release 전 | plugin manifest |
| 카테고리별 `template.md` 작성 (9개) | 메인테이너 | v0.1 release 전 | [[spec-11-medi-docs-frontmatter]] 결정 후 |

**시나리오 (사용자 첫 셋업)**

1. 신입 백엔드: Claude Code 설치 → `claude plugin marketplace add github:medisolve/harness` → `claude plugin install harness`.
2. `harness` 호출.
3. skill 상태 확인 → "설치된 plugin 0개, medi_docs/ 부재" → *처음 셋업* 분기.
4. dry-run: "역할은? backend 라면 base + backend plugin install + medi_docs/current/ 9 카테고리 scaffold. 진행?"
5. 동의 → 실행. `medi_docs/current/{planning,plan,...,retrospective}/` + 각 README/template + `_map.md` 생성.

**시나리오 (v1.0 cut)**

1. v1.0 출시 직전 → `/medi:version-cut` 호출.
2. skill: "버전 라벨? `v1.0` / `2026Q2` 등 자유 입력".
3. 사용자: `v1.0`.
4. D1 검증 → R4-R9 + frontmatter 누락/위키링크 끊김 검사 → 통과.
5. `current/` 전체 → `v1.0/` 복사 + `_map.md` 박제.
6. `current/` 그대로 유지 → v1.1 작업 incremental.

## Consequences

**Pros**
- *플러그인 깔면 정형화된 문서구조가 만들어진다* — mediness 핵심 가치 직접 실현.
- 9 카테고리 풀셋으로 개발 사이클 전체 커버 — 사용자·Claude 학습 비용 ↓.
- carry-forward 모델로 살아있는 작업 + 시점 박제 동시 — 시간축 추적 자연.
- install hook 강제 X — 사용자 통제권 보존.
- frontmatter 어휘 통일 → harness 도구가 사용자 medi_docs 에도 multi-target 검증.

**Cons**
- 9 카테고리 모두 활용 안 하는 작은 프로젝트는 빈 디렉토리 부담 — README 가 *언제 채울지* 안내 필요.
- 첫 사용자는 9 카테고리 의미 학습 시간 — onboarding 비용 ↑ (한 번만).
- carry-forward 가 의도된 누적이지만 *실수로 v1.0 잘못된 결정이 v1.1 까지 흘러갈* 위험 — `supersedes` 어휘로 명시 필요.
- v{label}/ 박제가 git history 와 별개로 누적 → 디렉토리 부풀기 (운영 후 archive 정책 검토).
- D2 (v{label}/ 불변) 가 경고 수준이라 메인테이너 자기 규율 의존.

**Follow-ups**
- [ ] cut 결과물 자동 commit 옵션 (`--commit` 플래그) 도입 여부 — 운영 패턴 측정 후 결정.
- [ ] 오래된 v{label}/ archive 정책 (n 버전 이상 시 git history 만 남기고 디렉토리 제거).
- [ ] 빈 카테고리가 *오래 비어있는* 프로젝트의 처리 (안내 / 자동 제거 / 그대로).

## Notes

- 2026-04-29: status proposed → accepted. source [[spec-10-medi-docs-scaffold]] status → accepted (통째 흡수).
- 2026-04-29: §7 (진입점·lineage 위계) 추가 + §6 D4 강제 룰 추가. `planning/` 단일 진입점, `plan/` 은 파생 진실, 나머지 카테고리는 `sources:` 그래프로 위계 표현.
