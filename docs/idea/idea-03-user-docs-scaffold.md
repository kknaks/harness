---
id: idea-03
type: idea
status: absorbed
created: 2026-04-28
tags: [idea, scaffold]
related_to:
  - "[[idea-02-mediness-architecture]]"
---

# User Docs Scaffold

## 요구사항

1. 유저 (이 플러그인 사용자) 가 harness 를 설치/사용하면 자기 프로젝트에 `medi_docs/` 가 자동 생성
2. `medi_docs/docs/` 아래에 **버전별** 로 spec · 정책 · 기획 등 문서 생성용 디렉토리가 잡혀 있어야 함
3. 유저 목표 = **하네스 (코드 자동화) + 문서화 (설계·정책·기획 누적)** 둘을 한 플러그인에서 같이 제공

## 동기

- harness 가 코드 작성 스킬만 주면 반쪽. 의사결정·정책·기획을 쌓을 표준 자리가 없으면 각 팀이 제각기 docs 구조를 만들고, 결국 Claude 가 매 프로젝트마다 docs 구조를 새로 학습해야 한다.
- 버전별 디렉토리 = "v1.0 시점의 spec/정책/기획" 스냅샷 → 시간축 추적 가능.
- harness 의 메타 docs (idea-02 의 `docs/idea` `docs/spec`) 와 다른 레이어다. 이건 **유저 프로젝트가 받는 콘텐츠 docs**.

## 옵션 검토

### A. `/medi:init` 한 방에 ad-hoc 생성

- pro: 단순. skill 한 개.
- con: 일회성. 버전 관리 부재.

### B. install/첫 사용 시 scaffold + skill 로 버전 cut ← 추천

- 플러그인 install hook (또는 첫 skill 호출) 에서 `medi_docs/` 생성.
- `/medi:version-cut v1.0` → `current/` 내용을 `v1.0/` 으로 스냅샷.
- `current/` 는 항상 "작업 중인 다음 버전".

### C. 별도 generator CLI

- pro: harness 와 분리, 다른 도구에서도 재사용.
- con: "harness + 문서화 통합" 이라는 핵심 목표가 약해짐.

## 디렉토리 스케치

9개 카테고리 풀셋 (개발 사이클 전체 커버):

```
<user-project>/
└── medi_docs/
    ├── current/                  # 살아있는 작업 상태 (carry-forward)
    │   ├── planning/             # 기획·요구사항·RFP — 무엇을
    │   ├── plan/                 # 마일스톤·스프린트·일정 — 언제·어떻게
    │   ├── spec/                 # 기술 명세 (API, 컴포넌트, 시스템)
    │   ├── policy/               # 도메인 정책·비즈니스 규칙
    │   ├── adr/                  # 결정 로그 (atomic)
    │   ├── runbook/              # 운영 절차·배포 가이드
    │   ├── test/                 # 테스트 시나리오·회귀
    │   ├── release-notes/        # 변경 이력 (사용자용)
    │   ├── retrospective/        # 회고·포스트모템
    │   └── _map.md               # auto (관계 그래프)
    ├── v1.0/                     # cut 시점 박제 (read-only)
    │   ├── planning/ · plan/ · ... · retrospective/
    │   └── _map.md               # 박제된 그래프
    └── v0.9/
        └── ...
```

각 카테고리 디렉토리 안: `README.md` (1-screen 안내) + `template.md` (frontmatter 스키마 + 본문 스켈레톤) + 실제 문서들.

사이클 매핑: `planning → plan → spec/policy → adr → 구현 → test → release-notes → runbook → retrospective`.

## 왜 `medi_docs` 인가

- harness 의 정체 (mediness, idea-02) 와 네이밍 일관성.
- 유저 프로젝트가 이미 `docs/` 를 가지는 경우가 흔함 → 충돌 회피용 별도 네임스페이스.

## 레이어 구분 (idea-02 와의 관계)

| 레이어 | 위치 | 누가 만지나 | 무엇 |
|--------|------|-------------|------|
| harness 메타 | (harness repo) `docs/idea` `docs/spec` `docs/adr` | harness 메인테이너 | harness 자체에 대한 의사결정 |
| harness 콘텐츠 | (harness repo) `content/inbox` … `content/harness` | harness 메인테이너 | 5단 파이프라인 |
| 유저 medi_docs | (user repo) `medi_docs/current/` + `v{label}/` | 유저 팀 (6 role) | 유저 프로젝트의 9 카테고리 산출물 |

세 레이어 모두 frontmatter·관계 어휘 (`sources`/`related_to`/`supersedes`/`depends_on`) 는 동일하지만 `_map.md` 는 분리.

**작성 도구는 재사용 X — 사용자 배포본은 별개 산출물**. 메인테이너용 `.claude/skills/docs-validate`, `docs-naming` 은 idea-02 의 권한 모델대로 사용자에게 노출되지 않는 내부 작업장 도구. 사용자용은 base plugin 안에 별도 패키징 (5단 파이프라인을 통과한 결과물). 핵심 로직 공유는 추후 코드 중복이 실제 문제로 떠오를 때 결정.

## 동작 흐름 (B 안 기준 + 결정 반영)

1. 유저가 harness plugin 설치 (Claude Code → marketplace add → install)
2. `harness` skill (spec-07) 호출 → "처음 셋업" 분기에서 medi_docs scaffold 동작:
   - `medi_docs/current/{9 카테고리}/` 생성
   - 각 카테고리에 `README.md` + `template.md` 동봉
   - `current/_map.md` 초기화
   - 이미 `medi_docs/` 가 존재하면 no-op (기존 자산 보호)
3. 유저가 `current/` 안에서 문서 작성:
   - `/medi:new <category> <slug>` 호출 → NN 자동 부여 + frontmatter 채움 + 본문 스켈레톤 복사
   - base plugin 의 `docs-validate` (사용자 배포본) 가 frontmatter·관계 검증 + `_map.md` 갱신
4. 새 작업 사이클 시작 시 `/medi:version-cut` 호출 → 스킬이 버전 라벨 명시적으로 묻고 (`v1.0`, `2026Q2` 등 사용자 자유):
   - cut **직전** 검증 통과 강제
   - `current/` 전체 → `v{label}/` 으로 복사·박제
   - `current/` 는 그대로 유지 (carry-forward) → 다음 사이클 incremental
5. 이후 `v{label}/` 은 read-only. 버전 간 차이 추적은 `diff -r v1.0/ v1.1/` 또는 git
6. plugin uninstall 시 `medi_docs/` 남김 (사용자 자산). uninstall 안내 메시지로만 처리

**사용자 배포본 도구 셋** (base plugin 안, 메인테이너용과 분리)
- `/medi:new <category> <slug>` — 새 문서 생성
- `/medi:version-cut` — 버전 박제
- `docs-validate` (사용자 배포본) — frontmatter·관계 검증, `_map.md` 자동 생성

## 결정

| # | 항목 | 결론 |
|---|------|------|
| Q1 | 버전 cut 트리거 | 수동 skill, 사용자가 버전 라벨 명시. git tag 자동 연동 X |
| Q2 | cut 직후 `current/` | carry-forward (그대로 유지). v1.x 박제 + current 살아있음 → 자연 diff |
| Q3 | 카테고리 분류 | 9개 풀셋: planning · plan · spec · policy · adr · runbook · test · release-notes · retrospective |
| Q4 | `_map.md` + 검증 도구 | 사용자 배포본은 base plugin 안 별도 산출물. 메인테이너용 `.claude/skills/docs-validate` 와 분리 (idea-02 권한 모델 준수) |
| Q5 | 버전 간 diff/lineage | 별도 도구 X. git/filesystem diff + 기존 `supersedes` 어휘로 충분 |
| Q6 | 기존 `docs/` 공존 | 별도 `medi_docs/` 네임스페이스로 충분. 충돌 회피 |
| Q7 | scaffold 시점 | `harness` skill (spec-07) "처음 셋업" 분기에 통합. install hook 강제 X |
| Q8 | role 분기 결합 | 카테고리 9개는 역할 무관 공통. 역할별 plugin 은 자기 도메인 템플릿/콘텐츠로 기여 (산출물 ⊥ 작업자) |
| Q9 | medi_docs 안 idea→spec 흐름 | 자연 폐기. 9 카테고리 자체가 사이클 흐름 역할 |
| Q10 | 카테고리 양식 깊이 | (c) README + template + frontmatter 스키마 + `docs-validate` 검증 — 표준화가 medi_docs 의 가치 명제 |
| Q11 | plugin uninstall 시 | `medi_docs/` 남김. 콘텐츠 = 사용자 자산. uninstall 안내 메시지로만 |
| (n) | 새 문서 생성 도구 | `/medi:new <category> <slug>` — base plugin 안 별도 산출물 |
| M1 | 사용자 배포본 도구 일습 | 현재 3개 (`new` / `version-cut` / `validate`) 셋으로 시작. 추가 (`version-list` / `category-add` / `lint` 등) 는 사용 패턴 본 후 — YAGNI |
| M3 | cut 직전 검증 실패 시 | **차단**. 박제는 깨끗한 상태에서만 의미. `--force` 옵션은 운영 후 결정 |
| M4 | 카테고리 간 cross-reference 어휘 | idea-02 4종 (`sources` / `related_to` / `supersedes` / `depends_on`) 그대로 재사용. medi_docs 전용 어휘 X |
| M5 | cut 시 `_map.md` 박제 | `v{label}/_map.md` 도 함께 박제. cut = 그 시점 전체 박제. `_map.md` 빠지면 박제된 그래프가 모호해짐 |
| M6 | 사용자 git workflow | cut skill 은 파일 시스템만 건드림. commit / PR 은 사용자 자유. 강제 X. 단 README 에 권장 컨벤션 (cut 결과물 = 1 commit) 안내 |

## 카테고리 양식 원칙 (M2)

9 카테고리 × 구체 스키마 결정은 별도 spec (spec-03 자매 — `medi-docs-frontmatter` owns 후보) 에서. **그 spec 이 따라야 할 idea 단계 원칙 7개**:

1. **공통 프론트매터** — 9 카테고리 모두 spec-03 의 공통 어휘 (`id`, `type`, 관계 4종) 그대로. medi_docs 전용 새 어휘 X.
2. **카테고리 = type** — `type: spec`, `type: policy`, ... 카테고리 이름 = `type` 값 (spec-03 패턴 재사용).
3. **파일명 패턴** — `{category}-NN-{slug}.md`. ADR 만 4자리 (`adr-NNNN-{slug}.md`). 메타 컨벤션 재사용.
4. **본문 스켈레톤 base 모델 두 개** — *spec계* (`Summary / Background / Goals / Design / Open Questions`) ↔ *adr계* (`Context / Decision / Consequences`). 9 카테고리는 둘 중 가까운 것에서 출발.
   - spec계: `spec`, `policy`, `planning`, `plan`, `runbook`, `test`, `release-notes`
   - adr계: `adr`, `retrospective`
5. **카테고리별 추가 필드 최소화** — 의미상 꼭 필요한 것만 (예: `release-notes` 의 `version`/`date`). 안 쓰는 필드 X.
6. **`template.md` = 단일 진실 원천** — 각 카테고리에 `template.md` 동봉. `/medi:new` 가 이걸 복사. 양식 변경 시 `template.md` 만 수정.
7. **검증 차등** — frontmatter 누락 = `docs-validate` 차단. 본문 섹션 누락 = 경고만 (강제 X).

## spec 단계로 분기

idea 결정은 위로 종료. 별도 spec 으로 분기되어야 하는 작업:

- **`medi-docs-frontmatter`** (가칭, spec-03 자매) — 9 카테고리 각각의 frontmatter 필드 + 본문 스켈레톤 구체. 위 7원칙 준수.
- **`medi-docs-tooling`** (가칭) — 사용자 배포본 도구 셋 (`new`/`version-cut`/`validate`) 의 인터페이스·동작 명세, base plugin 패키징 방식.
- **`docs-validate` 일반화** (spec 갱신 또는 신설) — 다중 루트·다중 카테고리 셋 처리. 메인테이너용은 그대로, 사용자 배포본은 별도 산출.

이 idea 자체는 **닫힌 상태로 promote** 가능.
