---
id: adr-0003
title: Content Pipeline
type: adr
status: accepted
date: 2026-04-29
sources:
  - "[[spec-01-content-pipeline]]"
tags: [adr]
aliases: []
depends_on:
  - "[[adr-0001-directory-structure]]"
related_to:
  - "[[adr-0002-permissions-flow]]"
  - "[[adr-0004-frontmatter-naming]]"
  - "[[adr-0006-onboarding-skill]]"
---

# Content Pipeline

## Context

(승격 원본: `docs/spec/spec-01-content-pipeline.md`)

Andrej Karpathy 의 [LLM Wiki 패턴](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) 에서 영감을 받았다.

> 매번 RAG 로 문서를 재합성하지 말고, LLM 이 읽은 내용을 위키로 쌓아두고 참조하자.

Karpathy 의 3단 흐름 (Raw → Wiki → Schema) 은 *지식 누적 + 활용* 의 본질을 잡지만, 사내 맥락에서 그대로 적용하면 두 가지 공백이 생긴다.

**공백 1 — raw 의 정체 모호**: 사내의 raw 자산은 정체불명 `SKILL.md`, 레거시 훅, 의도 모호한 디렉토리 등이 섞여 있다. 이 상태로 LLM 이 wiki 를 합성하면 *원본의 의도* 를 잘못 추정해 wiki 품질이 무너진다. → **sources 단계** 가 필요. raw 를 *정체화* (이름·목적 박음) + 이후 불변 박제.

**공백 2 — 결정 추적성 부재**: Karpathy 의 Schema 는 *활용* 단계 (지식 → 코드/스키마 추출). 우리는 그 전에 *시점의 결정* 을 atomic 로그로 박지 않으면 6개월 후 "왜 이렇게 했더라?" 에 답할 수 없다. wiki 안에는 다양한 합성·후보가 공존하므로, 진짜 채택된 결정만 추출해 박제할 단계가 별도로 필요. → **adr 단계** 가 필요.

**Karpathy ↔ mediness 매핑**

| Karpathy 3단 | mediness 5단 | 추가 의도 |
|--------------|--------------|-----------|
| Raw | inbox | 그대로 |
| — | **sources** ✚ | raw 정체화 + 불변 박제 |
| Wiki | wiki | 그대로 |
| — | **adr** ✚ | 결정 atomic 추출 + 시점 박제 |
| Schema | harness | 지식의 *활용 형태 = plugin 배포본* |

마지막 단계 명칭이 Karpathy 의 "Schema" 가 아닌 "harness" 인 이유: 사내에서 "지식의 활용 형태" 가 곧 사용자에게 배포되는 plugin 이라, 활용 매체 자체가 schema (구조화된 지식) 의 역할을 한다.

또한 사내 6 role (기획·PM·프론트·백엔드·QA·인프라) 이 같은 어휘로 작업해야 일관성이 유지되므로, 단계 의미와 관계 규칙을 한 번 결정으로 확정해야 한다.

**6 role 의 근거**: medisolve 조직 구성 그대로. 의사결정(기획·PM) / 개발(프론트·백엔드) / 품질·운영(QA·인프라) 3개 축으로 묶이지만 이 3축 분류는 *사후 해석* 이며, ADR 의 정당화는 "사내 조직 구조를 그대로 reflect 한다" 는 사실 자체. 조직 구조가 바뀌면 이 ADR 도 갱신·supersede 한다.

## Decision

**5단 파이프라인**

| 단계  | 이름      | 역할         | 입력             | 산출                     |
| --- | ------- | ---------- | -------------- | ---------------------- |
| 1   | inbox   | 집합소        | 사용자 제안, 레거시 자산 | raw dump               |
| 2   | sources | 1차 가공 = 원본 | inbox 항목       | 네이밍 + 목적 명시. 이후 불변     |
| 3   | wiki    | 합성·정리      | sources 문서     | **주제·기능 단위로** 비슷·연관 sources 묶고 다듬은 지식 노드 (project-agnostic) |
| 4   | adr     | 결정본 (ADR)  | wiki 결과        | atomic 결정 로그           |
| 5   | harness | 배포         | adr            | 배포 준비된 plugin          |

핵심: 한 단계 위로 갈수록 **결정**이 늘고 **자유도**가 준다.

**관계 규칙**
- 수평(같은 레벨): 양방향 `related_to` 가능.
- 수직(상위로): 단방향 승격만. 상위가 `sources` 로 출처를 가리킴.
- 어휘는 메타 레이어(idea/spec/adr)와 공용: `sources`, `related_to`, `supersedes`, `depends_on`.

**자산 단위**
- **inbox 직접 자식 = 1 자산 단위 (입력)**. 파일이면 1 .md, 디렉토리면 디렉토리 통째.
  - `content/inbox/note.md` → 파일 단위
  - `content/inbox/<name>/` (안에 `SKILL.md` + `scripts/` 등) → 디렉토리 단위 (통째 1 자산)
- **sources 박제 = 항상 `content/sources/sources-NN-<slug>.md` 1 file (출력)**. 입력이 디렉토리라도 .md 1 file 로 *평탄화* — frontmatter 1곳 SSOT + raw 본문 인용 통합. 디렉토리 자산의 file system 구조는 .md 본문 안 *각 파일별 코드 블록 인용* 으로 텍스트 보존.
- 평탄화 합성 책임: sh 가 frontmatter scaffold 박고, **Claude 가 본문 합성** (원본 인용 + 정체 한 줄) — ADR-0012 §1.
- inbox raw 는 그대로 둠 ([[adr-0002-permissions-flow]] §inbox 워크플로우 §4). sources 박제 후 메인테이너 수동 정리.
- 이후 단계 (wiki/adr/harness) 의 자산 단위는 단계별 의미에 따라 자유 — 운영 시 보강.

**6 role**: 기획 · PM · 프론트 · 백엔드 · QA · 인프라.

**status 라이프사이클** (콘텐츠 단계 자산 작업 추적)

각 단계 자산이 *어디까지 처리됐는지* frontmatter `status` 필드로 추적. 미박은 자산은 통과 ([[adr-0004-frontmatter-naming]] R9 — status 콘텐츠 단계 *선택*).

| 단계 | status 의미 |
|------|-------------|
| inbox | `pending` raw, sources 미처리 / `promoted` sources 박힘 / `archived` 정리 후 보존 |
| sources | `pending` 정체화 직후, wiki 미합성 / `promoted` wiki 합성됨 / `superseded` 정정 재박제 |
| wiki | `pending` 합성됨, ADR 미결정 / `promoted` content/adr 박힘 / `superseded` 재합성 |
| content/adr | `proposed` / `accepted` / `superseded` / `deprecated` (메타 adr 동일 — [[adr-0004-frontmatter-naming]] R9) |
| harness | `pending` 자산 입주 직후 / `released` plugin 배포됨 |

**자동 갱신 룰** (promote-docs sh 책임)

- `inbox-to-sources.sh` → 새 sources `status: pending` + 입력 inbox `status: promoted`
- `sources-to-wiki.sh` → 새 wiki `status: pending` + 입력 sources `status: promoted`
- `merge-sources-to-wiki.sh` → 입력 sources `status: promoted` (wiki 합성 진행 중이라 wiki status 미변)
- `wiki-to-adr.sh` → 새 adr `status: proposed` + 입력 wiki `status: promoted`
- `adr-to-harness.sh` → 새 harness 자산 `status: pending` (release 는 spec-09 V2 dogfood → V3 release 흐름에서 갱신)

자동 갱신은 sh 책임. 메인테이너가 직접 status 조작 가능 (예: superseded 표시, 정정 재박제).

**categories — 자산 인덱싱 차원** (콘텐츠 단계 권장, 메타 단계 선택)

자산을 *작업 종류* (코드 리뷰·테스트 설계·리팩토링·배포·모니터링 등) 로 분류하는 자유 어휘. plugin role (사람 역할) 과 다른 차원 — 같은 *코드 리뷰* SKILL 이 backend·frontend 둘 다 입주 가능. categories 는 그것을 가로지르는 facet.

```yaml
categories: [code-review, refactoring]
```

- **자유 enum** — 운영 중 자연 형성. 1000+ 자산 누적 후 클러스터 발견되면 enum 강제 ([[adr-0004-frontmatter-naming]] R 룰셋 강화 follow-up).
- **다중** — 한 자산이 여러 카테고리 가능.
- **인덱싱** — `content/_map.md` 가 카테고리별 카운트 자동 표시.
- 모든 type (idea/spec/adr/inbox/sources/wiki/harness) 공통 *선택* 필드.

**강제 룰** (docs-validate 가 검증; 구현은 도구 작업, 룰 명세는 이 ADR 의 결정)

| 룰 | 검증 대상 | 위반 시 |
|----|-----------|---------|
| **R1** 수직 단방향 | 모든 단계의 `sources` 필드 타깃이 *상위 단계* 인지 (예: wiki.sources → sources 만, sources → wiki 가리키면 위반) | **차단** |
| **R2** sources 불변 | `content/sources/` 단계 파일이 git history 상 머지 이후 수정되었는지 | **경고** (의도된 정정인 경우 메인테이너 판단) |
| **R3** 단계 건너뛰기 | `sources` 필드가 *바로 윗단계* 가 아닌 경우 (예: adr.sources → inbox 직접) | **경고** (의도된 단축 가능 — wiki 합성 없이 sources 가 곧 결정 자체인 케이스 등) |

추가로 wiki 합성 오류 (LLM 이 의미를 잘못 묶음) 는 도구가 잡지 못하므로 **wiki 단계의 인간 검토** 가 catch. 이 검토 의무는 wiki 단계의 정의 (`LLM 이 합성, 인간 검토`) 에 내재.

레이어 간(메타 ↔ 콘텐츠) 위키링크 참조는 원칙적으로 금지 (분리 유지). 예외 필요 시 별도 ADR 로 규약 추가.

## Alternatives Considered

| 안 | 단계 구성 | 채택 안 한 이유 |
|----|----------|------------------|
| 3단 (Karpathy 그대로) | Raw → Wiki → Schema | sources 부재로 raw 정체 모호 → wiki 품질 저하. adr 부재로 결정 추적성 0 |
| 4단 (sources 만 추가) | inbox → sources → wiki → harness | 결정 atomic 로그 없음. 시점의 *왜* 추적 불가 |
| 4단 (adr 만 추가) | inbox → wiki → adr → harness | raw 정체화 단계 없어 wiki 합성 품질 보장 불가 |
| **5단 ✓** | inbox → sources → wiki → adr → harness | 두 공백 모두 메움 |
| 6단 (spec 추가) | inbox → sources → wiki → spec → adr → harness | 콘텐츠는 *자산* (코드/스킬/지식), spec (조율 중) 은 *의사결정* 어휘. 메타 레이어에만 자연. 콘텐츠는 wiki 가 spec 역할 흡수 |

## Implementation Path

이 결정을 적용하기 위한 actionable 작업과 의존:

| Action                                                                                         | 누가             | 언제           | 의존 / 산출                                       |
| ---------------------------------------------------------------------------------------------- | -------------- | ------------ | --------------------------------------------- |
| 5단 디렉토리 (`content/{inbox,sources,wiki,adr,harness}/`) 생성 + 각자 `_map.md`                        | 메인테이너          | 콘텐츠 레이어 가동 시 | [[adr-0001-directory-structure]]                  |
| 단계별 frontmatter·파일명 컨벤션 적용                                                                     | 메인테이너 + new 스킬 | 콘텐츠 작성 시     | [[adr-0004-frontmatter-naming]]                   |
| 단계 간 승격 스크립트 4종 구현 (`inbox-to-sources` / `sources-to-wiki` / `wiki-to-adr` / `adr-to-harness`) | 메인테이너 도구       | 5단 가동 시작 시   | [[spec-05-promote-skills]], `promote-docs` 스킬에 추가 |
| `docs-validate` 가 R1/R2/R3 룰 구현                                                                | 도구 작업          | 콘텐츠 첫 운영 후   | [[spec-05-promote-skills]] follow-up                             |
| inbox PR 워크플로우 정착 (기여자 PR → 메인테이너 머지)                                                          | 모든 기여자         | inbox 가동 시   | [[adr-0002-permissions-flow]]                     |
| wiki 인간 검토 의무 정착                                                                               | 메인테이너          | wiki 가동 시    | —                                             |
| 6 role plugin 의 도메인 콘텐츠 기여                                                                     | 6 role         | 운영 중         | [[adr-0006-onboarding-skill]]                     |

**시나리오 예 (기여자가 자산 던질 때)**

1. 기여자가 `content/inbox/` 에 raw 자산을 PR.
2. 메인테이너 리뷰 → 머지 = **inbox 도착** (≠ 승격).
3. 메인테이너가 `inbox-to-sources.sh` 호출 → 자산을 *정체화* (이름·목적 박음) + `content/sources/` 에 박제.
4. (이후) `sources-to-wiki.sh` 로 비슷한 sources 묶어 wiki 노드, `wiki-to-adr.sh` 로 결정 추출, `adr-to-harness.sh` 로 plugin 배포.
5. 각 단계마다 `docs-validate` 가 R1/R2/R3 룰 검증 + `content/_map.md` 재생성.

각 단계 스크립트의 입력·산출 명세는 [[spec-05-promote-skills]] 의 후속 작업.

## Consequences

**Pros**
- 5단 단계가 명확해 도구·관계 규칙을 재사용할 수 있다.
- 메타·콘텐츠 어휘 대칭으로 학습 비용이 줄어든다.
- 6 role 이 공용 어휘를 공유해 일관성을 유지할 수 있다.

**Cons**
- 5단이 너무 많을 수 있음 — 작은 결정도 5단계를 통과해야 하는 부담이 생긴다.
- wiki 단계가 LLM 합성 + 인간 검토를 요구해 운영 부담이 있다.
- R2 (sources 불변) 가 경고 수준이라 메인테이너 자기 규율 의존. 강제 차단으로 올리려면 운영 후 sources 정정 빈도 보고 결정.
- 6 role 이 medisolve 조직 reflect 라 **조직 변경 시 ADR 갱신/supersede 부담**. 외부 도입 사례 발생 시 6 role 가정이 무너짐.

## Notes

- 2026-04-29: status proposed → accepted. source [[spec-01-content-pipeline]] status → accepted (통째 흡수).
- 2026-04-29: 5단 가동 e2e 첫 시도에서 발견 — *자산 단위* 명세 부재 갭. inbox 직접 자식 = 자산 단위 (파일/디렉토리), sources 박제 단위 보존 룰 박음. wiki 이상 단위는 운영 시 보강.
- 2026-04-29: 자산 단위 룰 즉시 정정 — sources 박제는 *항상 .md 1 file* (입력이 디렉토리라도 평탄화). frontmatter SSOT 1곳 + raw 본문은 .md 안 코드 블록 인용. 디렉토리 박제 모델 폐기.
- 2026-04-30: §status 라이프사이클 섹션 추가 — 콘텐츠 단계 자산 작업 추적 (status enum + sh 자동 갱신 룰). 3000+ 자산 확장 대비.
- 2026-04-30: §categories 차원 추가 — 자산 *작업 종류* 자유 enum, 다중. plugin role 과 다른 차원의 facet. content/_map.md 카테고리별 카운트 인덱싱.
