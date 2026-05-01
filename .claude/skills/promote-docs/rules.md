# Promote-Docs Rules

> 스킬이 강제하는 룰셋·정책·금지 사항. SKILL.md (사용자 시점 진입점) 가 trigger 시 로드 → 본 rules.md 는 실제 룰 적용 시점에 지연 로드 ([[adr-0007-skill-authoring-rules]] §1).

## Promotion Flow (모든 promote 요청 시작점)

신규 vs 머지를 임의로 정하지 말고 **항상 머지 후보 검토부터**:

1. **머지 후보 검토** — `docs/_map.md` 의 Specs (또는 ADRs) 섹션에서 기존 `owns` 목록을 본다.
2. **각 후보 spec 의 본문 `## Scope`** 를 읽어 의도 범위 확인.
3. **사용자 확인** — "이 idea 의 토픽이 spec-XX(`owns: foo`) 와 겹치나?" 명시적으로 묻기. 직감 X.
4. **분기**:
   - 매칭됨 → 「기존 spec 에 병합」 절차
   - 매칭 안 됨 → 「새 spec 으로 승격」 절차

머지 후보 검토는 default. 신규 생성은 매칭 없을 때만.

idea 파일은 항상 보존. 추적의 단방향 진실은 spec 의 frontmatter.

추적 필드 (frontmatter):
- `sources` (필수, 1개 이상) — 흡수한 idea 위키링크 리스트 (lineage)
- `related_to` (선택) — 양방향 소프트 링크
- `supersedes` (선택) — 단방향 하드 링크 (이 spec 이 다른 문서를 대체)
- `depends_on` (선택) — 단방향 의존 관계

`docs/_map.md` 의 Relations 섹션이 이 모두를 양방향 인덱싱 (`docs-validate` 가 자동 재생성).

## Content Pipeline Flow (콘텐츠 레이어)

콘텐츠 5단 (`inbox → sources → wiki → adr → harness`) 의 단계 의미와 합성 룰. **메타 레이어와 동일하게 머지 후보 검토 default**.

### 단계별 본질

| 단계 | 본질 | 단위 | 묶음 기준 |
|------|------|------|-----------|
| inbox → sources | **1:1 정체화** (raw → 이름·목적 박음) | inbox 직접 자식 = 1 자산 (파일 또는 디렉토리) | 묶음 X — 각 raw 가 각자 sources |
| sources → wiki | **N→1 합성** (project-agnostic 추출) | .md 1 file | **주제·기능 단위**. 같은 프로젝트라는 *우연한 동시성* 으로 묶지 말 것 |
| wiki → adr | **N→1 결정** (atomic 매핑) | .md 1 file | **자산 → plugin 매핑** 단위. 같은 매핑 결정 ADR 있으면 supersedes 또는 Notes |
| adr → harness | **1:1 배포** | plugin 자산 | 묶음 X — 1 결정 → 1 plugin 자산 |

### 합성 룰 (Claude 자동 분기)

**inbox → sources** (1:1):
- 입력 형태 (파일/디렉토리) 무관 → 항상 sources `.md` 1 file 평탄화 ([[adr-0003-content-pipeline]] §자산 단위)
- 비슷한 raw 라도 *각자 정체화* — wiki 단계에서 합성 자연
- merge sh (`merge-inbox-to-sources`) 는 *drilldown* (정정·재박제) 만

**sources → wiki** (N→1, 주제 단위):
- 묶음 기준 = **주제·기능** (코드 리뷰 / 테스트 설계 / 모니터링 / 배포 등) — *project-agnostic*
- 묶음 기준 ≠ 프로젝트 (NEXUS / Foo 등) — 같은 프로젝트라는 우연한 동시성으로 묶으면 *공용 plugin 추출* 가치 0
- **묶음 기준 ≠ 메타-내러티브** (lifecycle / 시리즈 / 워크플로우 / "X 의 4 단계" 등) — 합성자가 *발명한 상위 개념* 으로 독립 SKILL 묶지 X. 메타 관계는 wiki 본문 §관계 또는 ADR `depends_on` / `related_to` 로 표현.

### N→1 합성의 한계 — frontmatter `name:` 카운트 룰

입력 sources 의 *원본 inbox raw 인용* 영역에서 frontmatter `name:` 보유 파일을 카운트 (Claude Code SKILL 모델 / ADR-0007 §S1 — `name:` 가 박혀있다 = 자체 SKILL 정체).

| `name:` 카운트 | wiki 산출 |
|----------------|-----------|
| 0 | 1 wiki (raw 자료 자체가 SKILL 아님 — 일반 문서·sniipet) |
| 1 | 1 wiki (단일 SKILL 의 합성) |
| **N > 1** | **N wiki** (각자 별 wiki 로 합성) — 메타-내러티브로 묶지 말 것 |

`inbox-to-sources.sh` 가 디렉토리 입력 시 `name:` 카운트 stderr 진단 출력 — 합성자는 그 카운트만큼 wiki 박을 것.

**예외** — N>1 인데 1 wiki 가 정당한 케이스:
- 모든 `name:` 가 *같은 SKILL 의 split 표현* 인 경우 (예: 같은 SKILL 의 v1 / v2 / 실험 변형) — 드뭄
- 명시적 사용자 합의 후만 — 진단 출력 무시 사유를 ADR Notes 또는 wiki frontmatter `aliases:` 에 박는다

### 머지 후보 검토 default

각 wiki 박기 전:
  1. `content/_map.md` 에서 기존 wiki 목록 + 주제 확인
  2. 새 sources 의 *주제* 식별 → 기존 wiki 와 매칭?
  3. **사용자 확인** — "이 sources 의 주제가 wiki-XX 와 같은가?"
  4. 분기:
     - 매칭 → `merge-sources-to-wiki.sh <sources> <wiki>` (sources lineage 추가)
     - 매칭 X → `sources-to-wiki.sh <sources> <topic-slug>` (새 wiki)

### wiki 본문 합성 = 두 층 분리

  - 공용 골격 = 모든 프로젝트에 적용 가능한 패턴 (트리거·프로세스·출력 형식 등)
  - 프로젝트 의존 = 각 프로젝트의 컨벤션·인프라 가정 (Layer Objects, Mother 위치 등) — 분리 표시

**wiki → adr** (N→1, 자산 → plugin 결정):
- 결정 단위 = **이 자산이 어느 plugin (base / 6 role) 에 어떻게 들어가는가**
- 머지 후보 검토 default:
  1. `content/_map.md` 의 ADR 목록 확인
  2. 같은 plugin·자산 매핑 ADR 이미 있나?
  3. 분기:
     - 같은 결정 + 후속 학습 → 기존 ADR `## Notes` append
     - 결정 뒤집힘 → 새 ADR + `supersedes`
     - 새 매핑 → `wiki-to-adr.sh <wiki> <decision-slug> <role>`
- **자산 분리 룰** (wiki 두 층 → plugin 단계 처리):
  - **공용 골격만 plugin 본문에 박는다.** wiki §"공용 골격 (project-agnostic)" 그대로 입주.
  - **프로젝트 의존 슬롯은 plugin 본문에 박지 말 것.** 다음 셋 중 하나로 분리:
    - (a) **reference 로드** — 사용처 프로젝트 컨벤션 문서 (`docs/common/*.md`, `CLAUDE.md`) 를 SKILL trigger 시 로드. 부재 시 SKILL 내 *role-generic fallback* (예: NEXUS Layer Objects 가 아니라 "MVC/계층화 일반 원칙" 수준).
    - (b) **분기 ADR** — 특정 컨벤션 (NEXUS 등) 채택 사례 누적 시 별도 ADR `adr-NNNN-{convention}-{role}` 로 슬롯 박음 (병렬 채택, supersede X).
    - (c) **별도 plugin** — convention-specific plugin (`nexus-backend/` 등). role plugin 모델과 분리.
  - **금지** — wiki 의 두 층 분리를 *plugin 본문에서 다시 합치는 행위* (예: backend role plugin 본문에 NEXUS Layer Objects 박기). 분야 plugin 의 *role-generic* 의미 자기모순.
- **frontmatter 두 facet 박기** (ADR 단계의 *결정* 두 차원):
  - **`categories`** = topic facet — 자산 *작업 종류* (예: `[code-review]`, `[test-design]`). source wiki 의 categories 에서 전파 (`wiki-to-adr.sh` 가 자동). 운영 누적 후 동일 category 의 ADR 가 여러 role 에 분산되면 ADR-0011 §3 hoisting 트리거 후보.
  - **`role`** = plugin 매핑 facet — `base|planner|pm|frontend|backend|qa|infra` 중 하나 ([[adr-0011-base-hoisting]] §1 정의). 같은 wiki 자산이 *nuance 에 따라 다른 role* 로 별 ADR 갈라질 수 있음 (예: 같은 `code-review` topic 이 backend / frontend 별 ADR).
  - 두 facet 분리 → 같은 topic 의 자산이 여러 role 에 입주해도 *카테고리별 카운트* 와 *role별 분포* 가 `content/_map.md` 에서 가로질러 인덱싱됨.
- **sh 호출 직전 사용자 확인 (필수)** — `wiki-to-adr.sh <wiki> <slug> <role>` 의 3 인자 모두 사용자에게 명시 확인:
  1. **role** — 어느 plugin (`base|planner|pm|frontend|backend|qa|infra`) 에 입주? wiki §"프로젝트 의존 슬롯" 의 가정 (예: 백엔드 인프라) 으로 추정 가능하지만 *반드시 확인*. 같은 wiki 가 여러 role 로 분기될 수 있음 (별 ADR).
  2. **slug** — 결정 단위 파일명 끝. `{topic}-to-{role}` 패턴 권장 (예: `code-review-to-backend`). 분기 ADR 시 `{convention}-{topic}-to-{role}` (예: `nexus-code-review-to-backend`).
  3. role 인자 빠뜨리면 frontmatter `role:` 라인 미박힘 → validate R10 이 잡지만 사후. 호출 전 박는 게 정상.
- ADR 본문 6 섹션 (ADR-0004 표준 — 메타·콘텐츠 공통):
  - **Context** — wiki lineage + 결정 배경 (공용 골격 + 프로젝트 의존 슬롯 구조 + plugin 매핑 가설 후보)
  - **Decision** — atomic 결정 (자산 → plugin 매핑 + reference 분리 여부) + ADR-0011 hoisting 모델 적용
  - **Alternatives Considered** — wiki 의 *Plugin 매핑 가설* 들 + 검토한 다른 후보 + 채택 안 한 이유 (표 또는 리스트)
  - **Implementation Path** — 액션 아이템 표 (`Action / 누가 / 언제 / 의존`). 어느 plugin 의 어디에 / 어떤 자산 / 누가 / v0.x 에. 메타 ADR (예: `docs/adr/adr-0011-base-hoisting`) 의 표 그대로 패턴.
  - **Consequences** — Pros / Cons / Follow-ups (체크박스)
  - **Notes** — 시간순 append (status 전이, hoisting 가설, 자매 ADR 등)
- 6 섹션 모두 박는 것이 docs/adr 메타 ADR 과 동등한 정합. *Alternatives + Implementation Path 누락은 빈약*.

**adr → harness** (1:1 배포):
- ADR 결정 적용 → plugin 자산 입주 (실제 SKILL.md / hook / config 작성)
- ADR Notes 에 lineage 기록만 (sh 의 책임)

### 콘텐츠 레이어 frontmatter

콘텐츠 단계 frontmatter 명세 미정 (ADR-0004 line 130 — 운영 시 보강). 현재는 `id` + `type` + `sources` (위키링크 lineage) + `tags` 최소만 박는다 (sh 가 scaffold). 운영 중 자연 풍부화.

## Steps — 새 spec 으로 승격

(Promotion Flow 의 머지 후보 검토 후, 매칭 없을 때만)

1. **소스 확인** — idea 파일 존재 + `id`/`type` 프론트매터 보유.
2. **`owns` + Scope 합의** — 사용자와 (1) topic 이름(kebab-case) + (2) **Scope 한 줄**: 이 spec 이 다루는 범위. 다음번 머지 판단의 기준이 된다.
3. **스캐폴드** — `scripts/idea-to-spec.sh <idea> [slug]` → 9개 필수 필드 + Scope 슬롯 포함.
4. **본문 채우기** — `## Scope` 한 줄 작성 후 나머지 섹션.
5. **(선택) 관계** — `related_to`/`supersedes`/`depends_on` 필요 시 손으로 추가.
6. **검증 + _map 재생성** — `docs-validate/scripts/validate.sh`.
7. **보고** — 경로, owns, Scope, 검증 결과.

## Steps — 기존 spec 에 병합

1. **대상 확인** — idea + spec 둘 다 존재.
2. **Scope 확인** — spec 의 `## Scope` 가 idea 토픽을 포괄하는가?
   - 포괄 → 그대로 머지.
   - 부분 포괄 → spec.Scope 를 확장하는 게 자연스러운가? 아니면 신규?
   - 사용자에게 명시적으로 확인.
3. **머지** — `scripts/merge.sh <idea> <spec>` → spec 의 `sources` 에 추가, `updated` 갱신.
4. **본문 통합** — idea 의 핵심을 spec 본문에 반영. Scope 확장이 필요하면 같이 갱신.
5. **검증 + _map 재생성** — `docs-validate/scripts/validate.sh`.
6. **보고** — 갱신된 sources, Scope 변경 여부, _map 변경.

## Frontmatter Schema (spec)

`examples/spec-01-cli-shape.md` 가 정본 (관계 4종 모두 포함한 예).

| 필드 | 필수 | 값 |
|------|------|-----|
| `id` | ✓ | `spec-NN` |
| `title` | ✓ | 제목 |
| `type` | ✓ | `spec` |
| `status` | ✓ | `draft` \| `active` \| `decided` \| `deprecated` |
| `created` | ✓ | `YYYY-MM-DD` |
| `updated` | ✓ | `YYYY-MM-DD` |
| `sources` | ✓ | 흡수한 idea 위키링크 리스트 (1개 이상) |
| `owns` | ✓ | SSOT topic (유일) |
| `tags` | ✓ | 최소 `[spec]` |
| `aliases` | - | Obsidian alias |
| `related_to` | - | 양방향 소프트 링크 (idea/spec 모두 가능) |
| `supersedes` | - | 이 spec 이 대체하는 문서 |
| `depends_on` | - | 이 spec 이 의존하는 spec |

`sources` 블록 형식:
```yaml
sources:
  - "[[idea-02-cli-shape]]"
  - "[[idea-07-shell-completion]]"
```

## Body Skeleton

**spec** (Scope + 6 필수 + 2 선택):
```
# <Title>

## Scope             ← 이 spec 이 다루는 범위 (1~2문장). 머지 판단 기준. _map.md 에 노출됨.
## Summary           ← 1~2문장 TL;DR
## Background        ← sources idea 핵심 발췌, 동기
## Goals             ← 달성 목표 (불릿)
## Non-goals         ← 명시 제외 (불릿)
## Design            ← 구체 설계
## Open Questions    ← 미결 (체크박스)

<!-- 선택 (해당 시 주석 해제) -->
<!-- ## Interface              ← CLI / API / 파일 포맷 -->
<!-- ## Alternatives Considered ← 대안 후보 + 채택 안 한 이유 -->
```

**adr** (Michael Nygard 표준 + Notes 확장):
```
# <Title>

## Context
## Decision
## Consequences
## Notes        ← 시간순 append (status 전이, 적용 결과, 후속 학습)
```
- status / date 는 frontmatter.
- 결정 자체가 뒤집히면 새 ADR + `supersedes` 로 옛것 대체.
- sources 는 불변 lineage. 이후 추가 관련 spec 은 Notes 로 참조.

## Source spec status 전이 (spec→adr 시)

`spec-to-adr.sh` 는 ADR 만 생성 (status=`proposed`). **source spec status 는 자동 갱신 X** — 흡수 패턴이 케이스마다 다르기 때문. 메인테이너가 ADR lifecycle 진행에 따라 수동 갱신:

| 흡수 패턴 | source spec status | 시점 |
|-----------|---------------------|------|
| spec 통째로 한 ADR | `decided` | ADR 가 `accepted` 된 시점 |
| spec 의 일부 결정만 ADR (다른 부분 운영 명세로 살아있음) | `active` | ADR 가 `accepted` 된 시점 |
| spec 이 새 ADR/spec 으로 supersede | `deprecated` | supersede ADR/spec 이 `accepted` 된 시점 |

ADR 가 `proposed` 단계 (검토 중) 에는 source spec 그대로 (`draft` or `active`). ADR 가 `accepted` 로 굳을 때 위 표대로 spec 갱신.

ADR status 전이 자체:
- `proposed` — scaffold 직후. 검토 중.
- `accepted` — 메인테이너 합의 완료. 결정 효력 발휘. source spec status 도 같이 갱신.
- `superseded` — 새 ADR 가 `supersedes` 로 대체.
- `deprecated` — 더 이상 안 씀 (대체 ADR 없이 폐기).

## ADR Lifecycle — 관련 사항이 추가될 때

ADR 본문(Decision)은 **immutable** — 한 번 적힌 결정 텍스트는 거의 안 건드린다. 변화는 (1) `## Notes` append, (2) 새 ADR + 관계 필드, 둘 중 하나.

| 상황 | 처리 |
|------|------|
| 같은 결정 + 후속 학습·적용 결과 | 기존 ADR 의 `## Notes` 에 시간순 append |
| 같은 결정 + 관련 spec 추가 발견 | Notes 에 `[[spec-XX]]` 참조 (sources 는 불변) |
| status 전이만 (proposed → accepted 등) | frontmatter `status` + `date` 갱신, Notes 1줄 |
| 결정이 뒤집힘 / 대체 | 새 ADR + `supersedes: [[adr-NNNN-...]]` |
| 기존 결정 위에 부속 결정 | 새 ADR + `depends_on: [[adr-NNNN-...]]` |
| 비슷한 영역, 무관한 결정 | 새 ADR + (선택) `related_to: [[adr-NNNN-...]]` |

**자동 처리**: 관계 4종(`sources`/`related_to`/`supersedes`/`depends_on`) 만 쓰면 `_map.md` 가 자동 인덱싱하고 `validate.py` 가 사이클·끊긴 링크 잡는다.

**경계 신호**:
- Notes 가 너무 길어진다 → 새 결정으로 분기 시점
- 같은 영역에 ADR 3개+ → 상위 spec 재정리 시점

## Scripts (full reference)

**메타 레이어** (`docs/`)
- `scripts/idea-to-spec.sh <idea> [slug]` — idea → 새 spec 생성. **`[slug]` 옵션** 으로 1 idea → N specs 분할 시 충돌 방지 (kebab-case).
- `scripts/spec-to-adr.sh <spec> [slug]` — spec → 새 ADR 생성 (`docs/adr/adr-NNNN-{slug}.md`, status=proposed, body=Context/Decision/Consequences).
- `scripts/merge.sh <idea> <spec>` — 기존 spec 의 sources 에 idea 추가 (멱등).

**콘텐츠 레이어** (`content/`, adr-0003)
- `scripts/inbox-to-sources.sh <inbox-file> [slug]` — raw inbox 자산 → `content/sources/sources-NN-<slug>.md` (정체화 + 불변 박제). 본문은 *정체* (이름·목적) scaffold.
- `scripts/sources-to-wiki.sh <sources-file> [slug]` — sources → `content/wiki/wiki-NN-<slug>.md` (합성 scaffold). 실제 합성 본문은 Claude 가 채움.
- `scripts/wiki-to-adr.sh <wiki-file> [slug] [role]` — wiki → `content/adr/adr-NNNN-<slug>.md` (콘텐츠 ADR, 메타 ADR 카운터와 분리). role 인자: `base|planner|pm|frontend|backend|qa|infra`.
- `scripts/adr-to-harness.sh <content-adr> <plugin-name>` — ADR → plugin 적용 (Notes 에 lineage 기록만; 패키징은 spec-09 release flow 영역).

**SKILL scaffold + 동기화** (`.claude/skills/*` 또는 `content/harness/plugins/*/skills/*`)
- `scripts/create-skill.sh <skill-name> <location> [description]` — 신규 SKILL 디렉토리 + 4 필수 자산 (SKILL.md / rules.md / examples/sample-no-reference.md / checklist.md) scaffold. 기존 디렉토리 존재 시 exit 2 + sync-skill 사용법 안내.
- `scripts/sync-skill.sh <skill-dir> [--apply]` — `create-skill.sh` 의 *보편 슬롯* (SKILL.md 보안 §, rules/checklist SSOT docstring) 갱신을 기존 SKILL 에 idempotent additive 적용. dry-run 기본, `--apply` 로 실제 쓰기. 조건부 슬롯 (reference / phase / 출력 포맷 / examples 두 개) 은 다루지 않음 — 본 §"Skill / Wiki 합성 시 조건부 슬롯 체크리스트" 가 합성자 책임.

**1 idea → N specs 예시**:
```
idea-to-spec.sh docs/idea/idea-02-mediness-architecture.md content-pipeline
idea-to-spec.sh docs/idea/idea-02-mediness-architecture.md directory-structure
# ...
```

## Skill / Wiki 합성 시 조건부 슬롯 체크리스트

scaffold 가 *모든* SKILL·wiki 에 박는 것은 **보편 슬롯** (보안 마스킹·SSOT 분리) 만. 아래는 *type 별* 합성 시 추가로 박아야 하는 슬롯 — 해당하면 박고, 안 하면 *명시적 None* (예: "본 SKILL 은 reference 로드 안 함") 으로 표기.

scaffold heredoc 에 이 슬롯들을 미리 박아두면 (1) 해당 안 되는 SKILL 에 죽은 § 가 남고 (2) "type 별 매번 나올 영역" 이 아닌데 강제하는 자기모순. 따라서 *합성·scaffold 시 본 체크리스트 통과* 가 운영.

### A. SKILL 이 외부 reference (사용처 컨벤션 문서) 를 로드하는가?

해당 시 (예: backend `code-review` 가 `docs/common/*.md` + `CLAUDE.md` 로드):
- **rules.md** 에 `## reference 로드 모델` § 박기:
  - 우선순위 표 (1 > 2 > 3 fallback) — 어느 파일부터 어떤 순서로 읽는가
  - **충돌 시 룰** — 두 reference 가 같은 항목을 다르게 정의하면 어떻게 할지 명시 (예: "1번 우선" / "둘 다 박고 사용자에게 확인" / "엄격한 쪽")
  - **fallback 명시** — 모든 reference 부재 시 적용할 *role-generic* 항목 (구체 컨벤션이 아닌 일반 원칙)
  - **리포트에 출처 명시** 강제 — 이슈 발견 시 어느 reference 의 어느 룰인지 또는 `role-generic` 인지 박는다
- **examples/** 두 개 박기 (명시적 명칭 — 어느 케이스인지 파일명에서 식별):
  - `sample-with-reference.md` — reference 로드된 본문 (구체 컨벤션 인용)
  - `sample-no-reference.md` — fallback 만으로 동작한 본문
  - 단일 `sample.md` 는 모호 — 새로 박을 때는 위 두 명칭 사용. 기존 단일 `sample.md` 는 retrofit 시 명시적 명칭으로 rename.

### B. SKILL 이 phase·step 표 (시간 / 비중 / 단계) 를 갖는가?

해당 시 (예: 4단계 리뷰 프로세스):
- 표 헤더에 **강제 / 가이드 분리** 명시:
  - 시간/비중 컬럼은 *guideline* (예: "시간 (가이드)") — 강제 X 라는 사실을 헤더에 박는다
  - 본질·산출 컬럼은 *강제* (예: "본질" 또는 "필수 산출")
- 헤더 한 줄로 강제·가이드 구분이 안 된다면 컬럼 추가 (`강제도: 필수 / 권장`).
- 같은 표를 rules.md (본질) 와 checklist.md (실행 절차) 양쪽에 박지 말 것 — rules SSOT.

### C. SKILL 이 산출 포맷 (리포트·이슈 ID·정형 출력) 을 정의하는가?

해당 시 (예: code-review 가 `B-NNN`/`I-NNN` 이슈 ID + 마크다운 리포트 산출):
- **이슈 ID scope** 명시:
  - 단일 리포트 내 부여 / 누적 (도메인 내 unique) / PR 단위 / 영구 unique — 어느 scope?
  - scope 박지 않으면 사용자가 "이전 리포트의 B-001 이 이번 B-001 과 같은 이슈인가?" 헷갈림
- 필수 필드 (ID·출처·코드·우선순위) 표 + 누락 시 처리

### D. wiki 합성 시 — 위 A/B/C 가 wiki 본문에도 적용

`sources-to-wiki.sh` 의 scaffold 는 lean (Summary / Synthesis / References) — wiki 가 산출 포맷·reference 로드·phase 표를 정의한다면 *합성자 (Claude)* 가 §"형식 및 규약" 또는 적절한 § 를 추가해 박아야 한다. wiki 의 §리포트 포맷 슬롯 = 이슈 ID scope + 필수 필드. 본 체크리스트 통과는 합성자 책임.

### 미해당 시

해당 안 되는 SKILL/wiki 는 슬롯 박지 말 것. "본 SKILL 은 reference 로드 안 함 — fallback 만으로 동작" 같은 *명시적 None* 도 OK. scaffold 에 죽은 § 남기지 말기.

## Don't

- idea 파일 삭제 금지 — 모든 관계 위키링크가 끊김.
- `docs/_map.md` 직접 편집 금지 — 자동 생성물.
- 동일 `owns` 가 다른 spec 에 있으면 새로 만들지 말고 병합.
- `supersedes`/`depends_on` 사이클 금지 — validate 가 잡지만 처음부터 만들지 말 것.
- 번호 재사용 금지.
- wiki 두 층 분리를 plugin 본문에서 합치기 금지 (§자산 분리 룰 §금지).
- `wiki-to-adr.sh` 호출 시 role 인자 누락 금지 (§sh 호출 직전 사용자 확인).
