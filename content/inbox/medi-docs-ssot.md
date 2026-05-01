# medi-docs SSOT 위계 결정 (raw, ADR-0008 콘텐츠 부분 발췌)

> 출처: `docs/adr/adr-0008-medi-docs-scaffold.md` (메타 ADR). 콘텐츠 결정 부분만 발췌하여 5단 파이프라인 진입점으로 박음.
> 발췌 사유: ADR-0008 안에 메타 (harness 도구 동작) + 콘텐츠 (사용자 자산 내용 룰) 두 레이어가 섞여 있어, 콘텐츠 부분이 5단 파이프라인을 우회 → content/harness/plugins/base/medi-docs-templates/ 가 stale.
> 박은 시점: 2026-05-01.
> 보강: 2026-05-01 — 관계 4종 어휘 공유 / cut 동작 / uninstall / supersedes 의도 누락분 ADR-0008 원본에서 재추출.

---

## §0 레이어 구분 (= 매핑 어휘 공유 선언)

| 레이어 | 위치 | 누가 만지나 | 무엇 |
|--------|------|-------------|------|
| harness 메타 | (harness repo) `docs/idea` `docs/spec` `docs/adr` | harness 메인테이너 | harness 자체 의사결정 |
| harness 콘텐츠 | (harness repo) `content/inbox` … `content/harness` | harness 메인테이너 | 5단 파이프라인 |
| **유저 medi_docs** | (user repo) `medi_docs/current/` + `v{label}/` | 유저 팀 (6 role) | 유저 프로젝트의 9 카테고리 산출물 |

**세 레이어 모두 같은 frontmatter 어휘 (ADR-0004 R4-R9) 와 관계 4종 (`sources / related_to / supersedes / depends_on`) 을 공유한다.** 단 `_map.md` 는 레이어별 분리. medi_docs 는 사용자 자산이라 onboarding skill 의 *처음 셋업* 분기에서 의도 파악 후 lazy 생성 (install hook 강제 X — 사용자 통제권 보존).

---

## §1 9 카테고리 풀셋

```
medi_docs/
├── current/
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

각 카테고리: `README.md` (1-screen 안내) + `template.md` (frontmatter + 본문 스켈레톤) + 실제 문서들.

**사이클 매핑**: `planning → plan → spec/policy → adr → 구현 → test → release-notes → runbook → retrospective`.

## §2 current/ + v{label}/ carry-forward 모델

| 시점 | current/ | v{label}/ |
|------|---------|-----------|
| t0 scaffold | 빈 9 카테고리 + README/template | 없음 |
| t1 작업 중 | spec-01-foo.md 생성 | 없음 |
| t2 v1.0 cut | (그대로 유지) | v1.0/ = t1 스냅샷 박제 |
| t3 후속 작업 | spec-01-foo.md 수정 | v1.0/ 그대로 (read-only) |
| t4 v1.1 cut | (그대로 유지) | v1.1/ = t3 스냅샷 |

current/ = 살아있는 incremental 작업 상태, v{label}/ = 박제된 시점 스냅샷.
`diff -r v1.0/ v1.1/` 로 자연스러운 정책 변화 추적.

## §3 cut 동작 (매핑 박제 포함)

- **트리거**: 수동 skill 호출 (`/medi:version-cut`). git tag 자동 연동 X (사용자 git workflow 침범 회피).
- **버전 라벨**: 사용자 자유 지정 (`v1.0`, `2026Q2`, `release-2026-04` 등). semver 강제 X.
- **검증 강제**: cut 직전 `docs-validate` 통과 필수. 실패 시 박제 차단.
- **박제 범위**: `current/` 전체 → `v{label}/` 으로 복사. **`_map.md` 도 함께 박제** (그 시점의 관계 그래프 동결).
- **carry-forward**: cut 후 `current/` 그대로 유지.
- **read-only**: `v{label}/` 는 cut 이후 수정 X. 변경 필요 시 새 cut.

## §5 uninstall 처리

- plugin uninstall 시 `medi_docs/` **남김** — 콘텐츠는 사용자 자산.
- uninstall 안내 메시지: "medi_docs/ 는 사용자 자산이라 보존됩니다. 필요 시 직접 삭제하세요."

## §6 D4 lineage 필수 (강제 룰)

| 룰 | 검증 대상 | 위반 시 |
|----|-----------|---------|
| **D4** lineage 필수 | 모든 비-planning 문서가 `sources:` 최소 1개 보유 (retrospective 만 다수 cross-cutting) | **차단** (`docs-validate` 실패) |

## §7 진입점·lineage 위계 (SSOT)

medi_docs 의 단일 진실 진입점은 `planning/` (최상위 진실 — *왜·무엇을*). `plan/` 은 planning 의 파생 진실 (*어떻게·언제*). 디렉토리는 §1 의 9 카테고리 flat 그대로 유지하고, 위계는 frontmatter `sources:` (ADR-0004 의 **관계 4종 어휘** 중 lineage 표현 1종) 로 표현한다. `related_to / supersedes / depends_on` 도 동일 어휘 풀에서 자유 사용.

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

## §C carry-forward 의 매핑 측면 위험 (Consequences 발췌)

carry-forward 가 의도된 누적이지만 *실수로 v1.0 잘못된 결정이 v1.1 까지 흘러갈* 위험 → **`supersedes` 어휘로 명시 필요**. (관계 4종 중 supersedes 의 medi_docs 내 명시적 용도.)

---

## 사용자가 알아야 하는 노출 채널 (현재 부재)

이 SSOT 위계가 실제 사용자에게 도달하려면:

1. `medi_docs/README.md` (루트 진입점) — §7 트리 + "planning 부터 읽어라" 1-screen + §0 의 *관계 4종 어휘 공유* 안내
2. `{category}/README.md` lineage 1줄 — 예: `spec/README` → "`sources:` 는 plan/* 를 가리킨다"
3. `{category}/template.md` `sources:` placeholder 구체화 — `[[planning-NN-...]]` / `[[plan-NN-...]]` 등 카테고리별 힌트 + `related_to / supersedes / depends_on` 사용 가이드
4. `_map.md` 자동 갱신 (lineage 트리 뷰 + cut 시 박제)

현재 `content/harness/plugins/base/medi-docs-templates/` 는 1, 2, 3, 4 모두 placeholder 상태.
