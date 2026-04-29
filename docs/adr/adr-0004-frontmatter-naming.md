---
id: adr-0004
title: Frontmatter Naming
type: adr
status: accepted
date: 2026-04-29
sources:
  - "[[spec-03-frontmatter-naming]]"
tags: [adr]
aliases: []
depends_on:
  - "[[adr-0001-directory-structure]]"
related_to:
  - "[[adr-0003-content-pipeline]]"
---

# Frontmatter Naming

## Context

(승격 원본: `docs/spec/spec-03-frontmatter-naming.md`)

8단 (메타 3단 + 콘텐츠 5단) 모든 문서가 *사람 + LLM + 도구* 세 주체 모두 같은 어휘로 읽고 쓸 수 있어야 한다. 도구 (`docs-validate`, `promote-docs`, Obsidian) 가 frontmatter 를 파싱해 관계 그래프를 인덱싱하고, LLM 이 그 그래프를 추론하며, 사람이 직접 손으로 작성·검토한다. 이 세 주체가 어긋나면 도구가 깨지거나, LLM 이 lineage 를 못 따르거나, 사람이 작성을 포기한다.

frontmatter 표준 후보를 비교했을 때:

| 후보 | 채택 안 한 이유 |
|------|------------------|
| Pandoc YAML | LaTeX/PDF 빌드 우선 표준 — 위키링크 어휘 없음. lineage 추적 불가 |
| JSON-LD / schema.org | linked-data 강력하지만 사람 직접 작성·검토 부담 큼. IDE/LLM 직관성 ↓ |
| TOML frontmatter (Hugo 등) | 위키링크 표준 없음. Obsidian 호환 X |
| 비-frontmatter (코멘트 마커 / 파일명만) | grep 안 됨. `_map.md` 자동 인덱싱 어려움 |
| **Obsidian YAML + 위키링크 + tags ✓** | 세 주체 (사람·LLM·도구) 모두 같은 어휘로 읽음. Obsidian 그래프/백링크/위키링크 자동 갱신. 외부 빌드 도구 의존 없음 |

ADR 본문은 Michael Nygard 표준 (Context / Decision / Consequences) + 사내 확장 (Alternatives Considered / Implementation Path / Notes) 을 따른다. inbox 만 raw 보존 예외 — `id`/`type` 최소 2 필드만.

번호 자릿수도 단계별 누적 속도가 다르므로 차등 결정한다 (idea/spec/콘텐츠 ~수십~100, ADR 1000+).

## Decision

**파일명**

| 단계 | 패턴 | 자릿수 근거 |
|------|------|--------------|
| inbox | 원본 그대로 (raw 보존) | 정체화 전이라 번호 부여 X |
| sources / wiki / harness | `{stage}-NN-{slug}.md` (NN = 2자리) | 콘텐츠 자산, 도메인 단위 누적 (수십~수백). 100 도달 시 자연 NN→NNN 확장 — `docs-validate` 정규식 `^{type}-([0-9]+)-` 가 흡수 |
| idea / spec | `{type}-NN-{slug}.md` (NN = 2자리) | 메타 의사결정. 좁은 운영 단위 (수십~100) |
| adr (메타·콘텐츠 공통) | `adr-NNNN-{slug}.md` (NNNN = 4자리) | atomic 결정 로그. 시점마다 누적되어 1000+ 가능. **MADR 외부 표준 호환**. 처음부터 4자리로 시각 표준화 (자릿수 변경 빈도 ↓) |

slug 는 모든 단계에서 kebab-case (`[a-z0-9]+(-[a-z0-9]+)*`).

**공통 프론트매터** (모든 단계)
- 필수: `id`, `type` (단계 이름과 일치)
- 관계 4종 (위키링크 리스트): `sources`, `related_to`, `supersedes`, `depends_on`

**spec 추가 필드** (9개 필수): `title`, `status`, `created`, `updated`, `sources`, `owns`, `tags`

**adr 추가 필드** (7개 필수): `title`, `status` (proposed / accepted / superseded / deprecated), `date`, `sources`, `tags`. `owns` 는 두지 않음 (atomic).

**inbox 최소 프론트매터**: `id`, `type: inbox` (1줄씩만 추가).

**본문 스켈레톤**

spec (6 필수 + 2 선택):
```
## Summary / Background / Goals / Non-goals / Design / Open Questions
<!-- 선택: ## Interface / ## Alternatives Considered -->
```

adr (Michael Nygard + 사내 확장):
```
## Context / Decision / Alternatives Considered / Implementation Path / Consequences / Notes
```

**강제 룰** (`docs-validate` 가 검증; 룰 명세는 이 ADR 의 결정. [[adr-0003-content-pipeline]] 의 R1-R3 와 분리되는 형식·참조·일관성 룰)

| 룰 | 검증 대상 | 위반 시 |
|----|-----------|---------|
| **R4** 필수 필드 | 단계별 필수 frontmatter 필드 (공통 `id`/`type`, spec 9개, adr 7개, inbox 최소 2개) | **차단** |
| **R5** 위키링크 끊김 | 관계 4종 (`sources`/`related_to`/`supersedes`/`depends_on`) 의 타깃 파일 존재 | **차단** |
| **R6** 파일명 패턴 | `{type}-NN-{slug}.md` (NN 2자리) 또는 `adr-NNNN-{slug}.md` (NNNN 4자리), slug 는 kebab-case | **차단** |
| **R7** id ↔ 파일명 일치 | frontmatter `id` 의 번호가 파일명 NN 부분과 동일 (예: `id: spec-10` ↔ `spec-10-foo.md`) | **차단** |
| **R8** type ↔ 디렉토리 일치 | frontmatter `type` 이 부모 디렉토리명과 동일 (`type: spec` ↔ `docs/spec/`) | **차단** |
| **R9** status 값 enum | spec: `draft/active/decided/deprecated` 4값만; adr: `proposed/accepted/superseded/deprecated` 4값만 | **차단** |

7개 모두 차단 강도 — frontmatter 가 깨지면 `_map.md` 인덱싱·promote-docs 스크립트·Obsidian 그래프 모두 못 동작. 경고 강도는 의미 X.

YAML 파싱 에러 (들여쓰기/quote 깨짐) 는 R4 가 *읽기 시점* 에 자연 fail — 별도 룰 불필요.

## Alternatives Considered

(Context 의 frontmatter 표준 후보 표 참조)

자릿수 차등의 대안:
- **모든 단계 4자리 통일**: 일관성 ↑, 단 idea/spec 이 좁은 단위라 0001~0010 만 차고 99% 의 0 이 시각 노이즈. 채택 X.
- **모든 단계 2자리 통일**: ADR 100 도달 시 자릿수 변경이 *자주* 일어남 → 도구 깨짐 빈도 ↑. 채택 X.
- **차등 (현재안) ✓**: 누적 속도에 비례.

본문 스켈레톤 대안:
- **Michael Nygard 3섹션 (Context/Decision/Consequences) 만**: 사내에서 *왜 다른 대안 아닌가* + *그래서 누가 무엇을* 가 빠짐. 채택 X (확장).
- **MADR 7섹션 (Status/Date/Decision Drivers/Considered Options/Decision Outcome/Pros and Cons/Links)**: 표준이지만 사내 어휘 (Implementation Path 등) 와 일부 중복. 채택 X (사내 5섹션 + Notes 로 단순화).

## Implementation Path

| Action | 누가 | 언제 | 의존 / 산출 |
|--------|------|------|--------------|
| `.claude/skills/docs-validate/scripts/validate.py` 가 R4-R9 룰 적용 | 도구 작업 | 메타 레이어 가동 (이미 진행 중) | 현재 R4-R8 일부 구현. R9 status enum 일부 누락 — 보강 필요 |
| `.claude/skills/promote-docs/scripts/*.sh` 가 본문 스켈레톤 + frontmatter scaffold 생성 | 도구 작업 | spec/adr/콘텐츠 신규 생성 시 | 메타 3개 (idea-to-spec, spec-to-adr, merge) + 콘텐츠 4개 (inbox-to-sources, sources-to-wiki, wiki-to-adr, adr-to-harness) |
| Obsidian vault 의 `userIgnoreFilters` 에 `_map.md` 등록 | 메인테이너 | 1회 셋업 | `.obsidian/app.json` (이미 적용) |
| 신규 frontmatter 필드 도입 시 ADR 갱신 (`R4-R9` 룰셋 변경) | 메인테이너 | 단계별 추가 필드 결정 시 | [[adr-0003-content-pipeline]] 의 단계별 의미 결정과 동기 |

**시나리오 예 (메인테이너가 새 spec 생성 시)**

1. `bash .claude/skills/promote-docs/scripts/idea-to-spec.sh <idea> [slug]` 호출
2. 스크립트가 NN 자동 부여 + 9 필수 필드 frontmatter + 본문 스켈레톤 scaffold
3. 메인테이너가 본문 손으로 채움
4. PostToolUse 훅 → `docs-validate` 가 R4-R9 검증 → 통과 시 `_map.md` 재생성
5. R5 (위키링크 끊김) 위반 시 차단 → 메인테이너가 타깃 파일 만들거나 링크 수정

## Consequences

**Pros**
- 사람·LLM·도구 세 주체가 같은 어휘로 읽고 쓰니 학습 비용 ↓, 도구 재사용 ↑.
- 관계 4종(`sources`, `related_to`, `supersedes`, `depends_on`)이 `_map.md` 자동 인덱싱 + Obsidian 그래프 양쪽 기반.
- 자릿수 차등 (NN/NNNN) 으로 자릿수 변경 빈도 ↓ — 도구 정규식 안정.
- ADR 4자리는 MADR 외부 표준 호환 — 미래 외부 도구 도입 시 마찰 ↓.

**Cons**
- frontmatter 가 깨지면 (YAML 파싱 / 필수 필드 누락 / 위키링크 끊김) `_map.md`·promote-docs·Obsidian 그래프 *전체* 가 멈춤 — 단일 실패점.
- 콘텐츠 단계별 (inbox/sources/wiki/harness) 추가 필드는 운영 시점에 결정 예정이라 이후 일관성 유지 부담.
- inbox raw 보존 예외로 인해 검증 룰이 분기되어 도구 복잡도 ↑.
- Obsidian 종속 — vault 가 없으면 위키링크 자동 갱신 부재. 다른 에디터 사용자는 수동 갱신.

## Notes

- 2026-04-29: status proposed → accepted. source [[spec-03-frontmatter-naming]] status → decided (통째 흡수).
