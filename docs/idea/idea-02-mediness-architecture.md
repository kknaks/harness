---
id: idea-02
type: idea
created: 2026-04-27
tags: [idea, architecture]
related_to:
  - "[[idea-01-distribution-strategy]]"
---

# Mediness Architecture

> 사용자가 작성한 README/비전 초안. 일부 텍스트가 잘려있어 재구성했음 — 검토 후 보강 필요.

## 정체성

**mediness** = Medisolve 공용 Claude Code 하네스. 각 역할 (백엔드 · 프론트 · 디자인 · QA · 기획 · PM) 이 공유하는 skills · settings · 가이드 · 지식을 한 레포에서 관리.

## 뿌리 — Karpathy LLM Wiki 패턴

Andrej Karpathy 의 [LLM Wiki 패턴](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) 에서 영감.

> 매번 RAG 로 문서를 재합성하지 말고, LLM 이 읽은 내용을 **위키로 쌓아두고** 참조하자.

Karpathy 3계층 (Raw / Wiki / Schema) 을 사내 맥락에 맞게 각색 + **하네스 배포 단위** 1단 추가 = 4단 파이프라인.

## 4단 파이프라인

| 단계 | 위치 | 역할 | 쓰기 권한 |
|------|------|------|-----------|
| 1. 원본 (Raw) | `sources/` | 불변 원본 문서 | 수집 도구만 |
| 2. 위키 (Wiki) | `wiki/` | 합성된 지식 | LLM (인간 검토) |
| 3. 스키마 (Schema) | `schema/` | 하네스 계약 | 메인테이너 |
| 4. 하네스 (Harness) | `harness/` | 배포 단위 | 메인테이너 |

추가로 `inbox/` — 1단 진입 전 심사 게이트.

## 디렉토리 구조

```
mediness/
├── inbox/              # intake gate (제출 대기, /mediness:review 로 심사)
├── sources/            # 1. 원본 (불변)
├── wiki/               # 2. 위키 — 합성된 지식
│   ├── pages/          #    크로스-역할 엔티티·개념·의사결정
│   └── roles/          #    역할별 자산
│       ├── backend/    #    v0.1 작업 중
│       ├── frontend/   #    placeholder
│       ├── design/     #    placeholder
│       ├── qa/         #    placeholder
│       ├── planning/   #    placeholder
│       └── pm/         #    placeholder
├── schema/             # 3. 스키마 — 하네스 계약 (skeleton)
├── harness/            # 4. 하네스 — 배포 단위
│   ├── skills/         #    skill 묶음 (⚠️ 플러그인화 미정)
│   ├── plugin/         #    .claude-plugin 메타 (⚠️ 플러그인화 미정)
│   └── shared/         #    역할 무관 공통
└── docs/               # 메타 (하네스 자체에 대한 의사결정만)
    ├── idea/           #    생각, 자유 형식
    ├── spec/           #    구체화 제안 (아직 결정 안 됨)
    └── adr/            #    확정 결정 (NNNN-<slug>.md, 형식 고정)
```

## 각 디렉토리 의미

### `inbox/` — intake gate

**제출 대기 큐.** 4단 파이프라인의 stage 가 아니라 원본 (stage 1) 에 들어갈 자격을 심사하는 대기실. 누구나 던지고, 중앙 책임자가 `/mediness:review` 로 승격·반려를 결정. 승인된 것만 `sources/` 로 이동.

### `sources/` — 1. 원본

**Raw 원본 문서 — 불변.** Anthropic 공식 문서, 외부 베스트 프랙티스, 사내 인시던트 로그·회고, 참고용 타사 하네스. 한 번 저장되면 수정 금지 (출처 신뢰성 유지).

### `wiki/` — 2. 위키

**LLM 이 `sources/` 를 합성한 지식** (Karpathy 원형).
- `pages/` — 크로스-역할 엔티티·개념·의사결정
- `roles/` — 역할별 자산 (skills · patterns · guides · CLAUDE.md 예정)

여러 역할이 공유하는 지식은 `pages/`, 특정 역할 전용은 `roles/<role>/`.

### `schema/` — 3. 스키마

**하네스가 따라야 할 계약.** 구체화 미정.
- `CLAUDE.md` 가 schema 안에 들어가야 하는지, 루트인지 결정 필요.
- 하네스 plugin 의 manifest 형식, skill 계약 등도 schema 의 후보.

### `harness/` — 4. 하네스

**배포 단위 — Claude Code 플러그인 형태로 짐작.**
- `skills/` — 사용자 호출 / 자동 호출 스킬
- `plugin/` — `.claude-plugin/plugin.json` 등 메타
- `shared/` — 역할 무관 공통 자산
- 플러그인화 구체 방법은 미정 (idea-01 distribution-strategy 와 결합 필요).

### `docs/` — 메타 디렉토리

하네스 **자체** 에 대한 의사결정만 담는 메타 디렉토리. 코드 레포의 ADR 과 다른 스코프 — 디렉토리 구조 변경, 역할 추가/분리, 배포 모델 전환, 컨벤션 변경 등.

- `idea/` — 자유 형식 thoughts
- `spec/` — 구체화 제안, 아직 결정 안 됨
- `adr/` — 확정 결정, 형식 고정 `NNNN-<slug>.md`

## 로드맵

- **v0.1** — 기본 구조 + `wiki/roles/backend/` 내용 채우기
- **v0.2** — `wiki/roles/frontend/`
- **v0.3** — `wiki/roles/design/`, `wiki/roles/qa/`
- **v0.4** — `wiki/roles/planning/`, `wiki/roles/pm/`

## Obsidian

이 레포는 Obsidian vault 로 사용. 모든 문서는 `[[wikilink]]` 문법으로 상호 참조.

## 레이어 분리 (중요)

이 비전은 **콘텐츠 레이어** 의 설계다. 두 레이어가 독립적으로 공존:

| 레이어 | 위치 | 무엇 | 누가 만지나 |
|--------|------|------|-------------|
| **콘텐츠** | `inbox/` `sources/` `wiki/` `schema/` `harness/` | 사내 지식의 합성·정제·배포 라인 (Karpathy 차용) | 모든 기여자 + 메인테이너 |
| **메타** | `docs/idea/` `docs/spec/` (`docs/adr/` 가능) | 하네스 프로젝트 자체에 대한 의사결정 | 메인테이너 |

→ 콘텐츠 레이어 도입은 메타 레이어 (우리가 만든 docs-validate 등) 에 영향 없음.

## Open Questions (콘텐츠 레이어 설계)

- [ ] `schema/` 의 구체적 정의 — 어떤 형태의 "계약" 인가 (manifest? validator? 뭐든)
- [ ] `CLAUDE.md` 위치 — schema/, roles/<role>/, 루트?
- [ ] inbox 심사 절차 자동화 (`/mediness:review` 동작 명세)
- [ ] sources 수집 도구 — 불변 원본 어떻게 가져오는가, 검증은
- [ ] wiki 갱신 주기 / 트리거 — sources 변경 시 자동? 수동?
- [ ] `roles/<role>/` 에 들어갈 자산 형식 — skills 만? patterns/guides 도?
- [ ] 6개 역할 분류가 최종? — devops 가 빠짐 (별도? planning 흡수?)
- [ ] 배포 (idea-01) 와 결합 — `harness/` 가 plugin source-of-truth, marketplace 가 publish target?
- [ ] 한 plugin 이 여러 role 커버? 또는 role 별 plugin?

## Open Questions (메타 레이어, 선택)

- [ ] `docs/adr/` 추가 시점 — 지금? 결정사항 누적된 후?
