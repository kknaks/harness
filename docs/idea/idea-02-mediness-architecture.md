---
id: idea-02
type: idea
status: absorbed
created: 2026-04-27
tags: [idea, architecture]
related_to:
  - "[[idea-01-distribution-strategy]]"
---
****
# Mediness Architecture

> v2 초안 — 5단 파이프라인 의미 재정의 + 관계 규칙 명시. 디렉토리 구조는 이 프로젝트에 맞게 재설계 예정.

## 정체성

**mediness** = Medisolve 공용 Claude Code 하네스. 6개 역할(**기획·PM·프론트·백엔드·QA·인프라**) 이 공유하는 skills · settings · 가이드 · 지식을 한 레포에서 관리.

## 뿌리 (변경 없음) — Karpathy LLM Wiki 패턴

Andrej Karpathy 의 [LLM Wiki 패턴](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) 에서 영감.

> 매번 RAG 로 문서를 재합성하지 말고, LLM 이 읽은 내용을 **위키로 쌓아두고** 참조하자.

Karpathy 의 Raw → Wiki → Schema 흐름을 사내 맥락에 맞게 **5단 파이프라인** 으로 확장. 뿌리(점점 정제되는 단방향 파이프라인 + 위키 누적) 만 유지하고, 단계 명칭·역할·디렉토리 구조는 모두 이 프로젝트 기준으로 재정의한다.

## 5단 파이프라인 (재정의)

| 단계 | 이름 | 역할 | 입력 | 산출 |
|------|------|------|------|------|
| 1 | **inbox** | 집합소 | 사용자 제안, 레거시 스킬·훅·디렉토리 등 정리 안 된 자산 | raw dump |
| 2 | **sources** | 1차 가공 = 원본 | inbox 항목 | 네이밍 수정 + 목적 작성된 "원본 취급" 문서. 이후 불변. 예: 정체불명의 `SKILL.md` 를 "어떤 스킬인지" 명확히 한 채 보존 |
| 3 | **wiki** | 합성·정리 | sources 문서들 | 비슷한/연관 내용을 묶고 다듬은 지식 노드. LLM 이 이 단계까지 합성, 인간 검토 |
| 4 | **adr** | 결정본 (ADR) | wiki 결과 | 한 결정 = 한 ADR 파일. atomic 결정 로그 |
| 5 | **harness** | 배포 | adr | 배포 준비된 플러그인 |

핵심: 각 단계는 **점점 정제** 된다. 한 단계 위로 올라갈수록 "결정"이 늘고, "자유도" 가 준다.

## 관계 규칙

문서 간 연관 방식은 우리가 이미 쓰고 있는 idea ↔ spec lineage 와 같은 모양으로, 단 단계가 5개로 늘어난 형태.

- **같은 레벨 (수평)** — 상호 연관(양방향) 가능. 예: inbox 안 두 항목이 비슷한 주제면 `related_to`. wiki 안 두 페이지도 마찬가지.
- **상위 레벨 (수직)** — **단방향** 만. 하위가 상위로 승격되거나 흡수된다. 상위에서 하위로 거꾸로 참조하지 않는다.
  - 예: `wiki` 노드는 `sources: [...]` 로 자기를 만든 sources 문서를 가리킨다. sources 가 wiki 를 가리키지 않는다.
  - 동일 패턴: 현재 spec 의 `sources: [idea-NN]`.
- 관계 종류는 기존 어휘 재사용: `sources` (승격 lineage), `related_to`, `supersedes`, `depends_on`.

이 규칙이 정착하면 lineage 그래프가 "inbox → sources → wiki → adr → harness" 한 방향으로만 흐르고, 각 레벨 안에서만 자유롭게 그물처럼 엮인다.

## 레이어별 인덱스 — `_map.md` 두 개

레이어가 분리되어 있으므로 `_map.md` 도 레이어당 하나씩.

- `docs/_map.md` — 메타 인덱스 (idea / spec). 현재 운영 중.
- `content/_map.md` — 콘텐츠 인덱스 (inbox → sources → wiki → adr → harness).

규약은 둘 다 동일.
- 같은 관계 어휘(`sources`, `related_to`, `supersedes`, `depends_on`).
- 같은 출력 포맷(Relations / 단계별 표 / lineage 뷰).
- 같은 검증 도구(기존 `docs-validate` 를 확장하되, 두 루트를 각각 스캔해 두 개의 `_map.md` 를 생성).

레이어 간(메타 idea ↔ 콘텐츠 wiki 등) 참조는 원칙적으로 하지 않음 — 분리 유지.

## 디렉토리 구조

메타와 콘텐츠를 형제 디렉토리로 분리, 각자 자기 `_map.md` 보유.

```
{repo-root}/
├── docs/                  ← 메타 (하네스 자체 의사결정)
│   ├── _map.md            ← 메타 인덱스
│   ├── idea/
│   ├── spec/
│   └── adr/
└── content/               ← 콘텐츠 (5단 파이프라인)
    ├── _map.md            ← 콘텐츠 인덱스
    ├── inbox/
    ├── sources/
    ├── wiki/
    ├── adr/
    └── harness/
```

- `harness/` 는 `content/` 안에 둠 — 배포 시 packaging 스크립트가 가져감. (분리 노출 여부는 추후 결정)

## 파일명 / 프론트매터 컨벤션

| 단계 | 파일명 | 프론트매터 |
|------|--------|------------|
| 1. inbox | **원본 그대로 (raw)** | 최소 (`id`, `type: inbox`) |
| 2. sources | `sources-NN-{slug}.md` | 표준 |
| 3. wiki | `wiki-NN-{slug}.md` | 표준 |
| 4. adr | `adr-NNNN-{slug}.md` (4자리, 누적 빠름) | ADR 표준 (`status`, `date`, `supersedes`) |
| 5. harness | `harness-NN-{slug}.md` (or plugin manifest 형식) | 표준 |

- **파일명**: 기존 `docs-naming` 컨벤션을 5단으로 일반화 — `{stage}-{NN}-{slug}.md`. inbox 만 예외(raw 보존), adr 만 4자리.
- **프론트매터**: Obsidian 규칙(YAML + wikilink + tags) 그대로. 1단 inbox 부터 적용.
  - 공통 필수: `id`, `type` (단계 이름).
  - 관계 필드: `sources`, `related_to`, `supersedes`, `depends_on` — 모두 위키링크 리스트.
  - adr 추가 필드: `status` (proposed / accepted / superseded / deprecated), `date`. 본문은 Context / Decision / Consequences.

## 레이어 권한

| 레이어 / 단계 | 누가 쓰기 | 비고 |
|---------------|-----------|------|
| 메타 (`docs/idea`, `docs/spec`, `docs/adr`) | 메인테이너 | 하네스 자체 의사결정 (idea→spec→adr 3단) |
| 콘텐츠 1단 `inbox/` | **모든 기여자 (공용)** | 누구나 던지는 raw 집합소 |
| 콘텐츠 2~5단 (`sources` → `harness`) | 메인테이너 | 정제·승격은 메인테이너 책임 |

원칙: **inbox 만 공용 입구**. 그 너머의 정제·승격은 메인테이너가 담당. 콘텐츠 레이어 도입은 메타 레이어 운영(`docs-validate` 등) 에 영향 없음.

## 승격 절차 (대화형 스킬 → 단계적 자동화)

원칙: **초반에는 모두 대화형 스킬로**, 이후 한 단계씩 자동화로 전환.

- "수동" = 직접 파일 이동/복사가 아니다. 메인테이너가 **스킬을 호출** 하고 Claude 와 대화하며 문서를 생성·승격.
  - 예: "이 inbox 항목을 wiki 로 올리자" → 스킬이 후보 wiki 노드를 제안, 메인테이너가 다듬고 확정.
- 검증된 패턴: idea→spec 의 `promote-docs` 스킬 — `promote.sh` / `merge.sh` + Claude 합성.
- 5단으로 일반화: `inbox→sources`, `sources→wiki`, `wiki→adr`, `adr→harness` 각각 스킬을 둠 (또는 한 스킬 + stage 인자).
- "자동화" = 메인테이너 호출 없이 트리거(훅, 스케줄)로 동작하는 단계. 빈도·오류율 높은 곳부터 점진 적용.
- 단계별 스킬 명세·자동화 시점은 별도 idea/spec 으로 분기 (지금 결정하지 않음).

## 외부 노출 = inbox 입구 + harness 출구

콘텐츠 5단 중 외부에 보이는 건 **양 끝** 둘뿐. 가운데 3단(sources/wiki/adr)은 메인테이너의 내부 작업장.

| 단계 | 외부 인터페이스 | 흐름 |
|------|------------------|------|
| inbox | **Git PR (입구)** | 기여자가 PR → 메인테이너 머지 = inbox 등재 |
| sources, wiki, adr | 없음 (내부) | 메인테이너 직접 push (PR 없이) |
| harness | **plugin 배포 (출구)** | 사용자는 이것만 받아 씀, 상위 단계는 모름 |

핵심:
- 기여자는 inbox 만 본다. 비개발 역할 포함 모두 PR 로 던진다.
- **sources 이후는 메인테이너 자유 영역** — PR 도, CODEOWNERS 도 불필요. 자기 규율 + 가벼운 관례면 충분.
- 사용자는 harness 만 쓴다 — 상위 단계는 비공개여도 무방.

머지(inbox) ↔ 승격(sources→) 은 별개. inbox 머지는 도착일 뿐, 승격은 별도 스킬로 메인테이너가 트리거.

## 메타 레이어 3단 (idea → spec → adr)

- `docs/idea/` — 자유 형식 thoughts.
- `docs/spec/` — 조율 중 제안. status 필드로 진행 상태.
- `docs/adr/` — 확정 결정. atomic, supersedes 체인.

콘텐츠 5단(inbox → sources → wiki → adr → harness)과 어휘·구조가 대칭. 어디까지 ADR 로 굳힐지는 운영하며 결정.

## 다른 idea 로 위임

- **harness 단위** (role별 plugin vs 통합 plugin) → [[idea-01-distribution-strategy]] 에서 결정.
