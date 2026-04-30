---
id: adr-0012
title: Promote Skills
type: adr
status: accepted
date: 2026-04-29
sources:
  - "[[spec-05-promote-skills]]"
tags: [adr]
aliases: []
depends_on:
  - "[[adr-0003-content-pipeline]]"
  - "[[adr-0004-frontmatter-naming]]"
related_to:
  - "[[adr-0011-base-hoisting]]"
---

# Promote Skills

## Context

(승격 원본: `docs/spec/spec-05-promote-skills.md`)

mediness 는 두 layer 의 단계 간 승격이 있다:

- **메타 layer**: idea → spec → adr (3 단)
- **콘텐츠 layer**: inbox → sources → wiki → adr → harness (5 단, [[adr-0003-content-pipeline]])

각 전환은 *문서 형식 변환 + 본문 합성* 두 단계 — 형식은 스크립트, 합성은 Claude. 메타 layer 의 `idea-to-spec` 패턴이 검증되어 모든 단계 간 승격에 일반화.

## Decision

### 1. 모든 승격 = 대화형 skill (메인테이너 + Claude)

스크립트가 frontmatter·파일명·lineage 박고, Claude 가 본문 합성. 둘이 한 skill 안에 같이.

### 2. 단계별 분리 — 모든 케이스 *생성 + 병합* 두 sh

콘텐츠 5단 + 메타 3단 모두 *피라미드 구조* (위로 갈수록 N→1 응축). 따라서 모든 단계 전환에 **신규 생성** sh + **기존 병합** sh 두 옵션이 본질적으로 자연. 각 단계 frontmatter 스켈레톤 차이로 단계별 분리 (통합 sh + stage 인자 X).

| 케이스 | 생성 sh | 병합 sh | layer |
|--------|---------|---------|-------|
| inbox → idea (메타 정책 triage) | `inbox-to-idea.sh` | `merge-inbox-to-idea.sh` | 메타 |
| idea → spec | `idea-to-spec.sh` | `merge.sh` | 메타 |
| spec → adr | `spec-to-adr.sh` | `merge-spec-to-adr.sh` | 메타 |
| inbox → sources | `inbox-to-sources.sh` | `merge-inbox-to-sources.sh` | 콘텐츠 |
| sources → wiki | `sources-to-wiki.sh` | `merge-sources-to-wiki.sh` | 콘텐츠 |
| wiki → adr | `wiki-to-adr.sh` | `merge-wiki-to-adr.sh` | 콘텐츠 |
| adr → harness | `adr-to-harness.sh` | `merge-adr-to-harness.sh` | 콘텐츠 |

총 14 sh (7 생성 + 7 병합). *틀로 박음, 본문은 단계 운영 시작 시 보강* — 메타 측 idea→spec 만 생성·병합 둘 다 동작, 나머지 12 sh 는 scaffold 또는 placeholder (`exit 99`).

merge sh 명명 컨벤션: `merge-<from>-to-<to>.sh`. 기존 `merge.sh` (idea→spec 한정) 는 backward-compat 유지, 차후 `merge-idea-to-spec.sh` 로 rename 검토 (follow-up).

### 3. 단일 skill `promote-docs` 가 모두 보유

- 위치: `.claude/skills/promote-docs/scripts/`
- skill 진입: 메인테이너가 `/promote-docs` 호출 → Claude 가 의도 파악 → 적절한 sh 자동 선택·호출 → 본문 합성.
- 일반화 완료 (2026-04-29 시점 7 스크립트 모두 존재).

### 4. 자동화 진입 기준 (사람 호출 → 훅·스케줄)

다음 셋 충족 시 해당 sh 를 훅 (예: PR 머지 후 자동 호출) 또는 스케줄로 승격:

- 동일 케이스 *자주 반복* (예: inbox → sources 가 매주 다수 발생)
- 사람 합성이 *거의 동일 패턴* 으로 굳음
- 합성 *오류율 낮음* (검증 단계가 잡아낼 수 있음)

자동화 우선순위 자체는 *운영 후 결정* (예측 X).

## Alternatives Considered

| 후보 | 채택 안 한 이유 |
|------|------------------|
| 통합 sh + `--stage` 인자 | 단계별 frontmatter 스켈레톤 다름 → 인자 분기 비대화 |
| 모든 승격 즉시 자동화 (훅) | 사람 합성 검증 안 된 채 자동화 = 오류 양산 위험 |
| skill 단계별 분리 (`promote-idea`, `promote-spec`, ...) | 7 skill 중복 진입점, 인지 비용 ↑. 단일 skill 안 분기가 가벼움 |
| 별도 자동화 도구 (CI 전담) | 메인테이너의 *대화형 검증 단계* 박탈 |

## Implementation Path

| Action | 상태 |
|--------|------|
| `idea-to-spec.sh`, `spec-to-adr.sh`, `merge.sh` (메타 생성/병합 idea→spec) | ✓ 구현 + 운영중 |
| `inbox-to-idea.sh` (메타 inbox triage 생성) | ✓ v0.1 신설 (ADR-0002 §inbox triage) |
| `inbox-to-sources.sh`, `sources-to-wiki.sh`, `wiki-to-adr.sh`, `adr-to-harness.sh` (콘텐츠 생성) | scaffold 구현. 입력·산출 명세는 콘텐츠 파이프라인 운영 시작 시 채움 |
| `merge-spec-to-adr.sh`, `merge-inbox-to-idea.sh`, `merge-inbox-to-sources.sh`, `merge-sources-to-wiki.sh`, `merge-wiki-to-adr.sh`, `merge-adr-to-harness.sh` (병합 placeholder) | v0.1 placeholder (`exit 99`). 단계 운영 + N→1 사례 발견 시 본문 보강 |
| skill `promote-docs` 일반화 | ✓ 완료 |
| 자동화 (훅·스케줄) 도입 | 운영 후 결정 (4번 기준 충족 케이스부터) |
| `merge.sh` → `merge-idea-to-spec.sh` rename (명명 통일) | follow-up |

## Consequences

**Pros**
- 모든 승격이 동일한 *대화형 + 스크립트* 패턴 → 메인테이너 학습 비용 1회.
- 단계별 sh 분리 → 각 sh 가 작고 명확. 단계 추가/변경 시 영향 범위 작음.
- 단일 skill 진입점 → "어떤 명령 써야 하지" 인지 비용 ↓.
- 자동화 진입 기준 명시 → 성급한 자동화 회피.

**Cons**
- 콘텐츠 단계 생성 sh 4개 + 병합 sh 6개 (콘텐츠 4 + 메타 2) 가 scaffold/placeholder — 콘텐츠 layer 운영 시작 전엔 검증 X.
- 단계별 sh 분리 = 코드 중복 가능 (frontmatter 갱신 로직 등). 헬퍼 추출은 운영 후 결정.
- 자동화 진입 *기준은 있지만 측정 도구 없음* — 빈도·오류율 측정 어떻게? 운영 후 결정.
- 14 sh 표가 비대 — 메인테이너 인지 부담. `promote-docs` skill 의 LLM 분기로 흡수.

**Follow-ups**
- [ ] 콘텐츠 단계별 sh 의 입력·산출 명세 (콘텐츠 파이프라인 운영 시작 시).
- [ ] 6 placeholder merge sh 본문 보강 (단계별 N→1 사례 발견 시 차례로).
- [ ] 단계 sh 들의 공통 헬퍼 추출 (frontmatter 갱신, lineage 박기, 파일명 NN 부여 등) — 중복이 명확해지는 시점.
- [ ] 자동화 진입 기준 *측정 도구* — 케이스별 빈도·오류율을 어디서 측정?
- [ ] 자동화된 sh 가 실패 시 fallback (사람 호출로 회귀) 패턴.
- [ ] `merge.sh` → `merge-idea-to-spec.sh` rename — 명명 통일.

## Notes

- 2026-04-29: [[spec-05-promote-skills]] → ADR 승격. spec OQ2 (skill 이름 일반화) 이미 완료 확인. OQ1 (콘텐츠 sh 명세) 운영 후 deferred 명시.
- 2026-04-29: §2 표 확장 — 모든 단계 *생성 + 병합* 두 sh 표준 (피라미드 N→1 응축 본질). 신설: `inbox-to-idea.sh` (메타 triage, 동작) + 6 placeholder merge sh (`merge-{spec-to-adr,inbox-to-idea,inbox-to-sources,sources-to-wiki,wiki-to-adr,adr-to-harness}.sh`). 본문은 단계 운영 시 보강.
