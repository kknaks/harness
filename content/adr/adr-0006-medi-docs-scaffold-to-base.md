---
id: adr-0006
title: medi-docs Scaffold → base plugin (4 책임 묶음)
type: adr
status: proposed
date: 2026-05-01
sources:
  - "[[wiki-06-medi-docs-scaffold-pattern]]"
tags: [adr, medi-docs, base, scaffold]
categories: [docs-scaffold]
role: base
aliases: [medi-docs-scaffold-to-base]
---

# medi-docs Scaffold → base plugin (4 책임 묶음)

## Context

승격 원본: `content/wiki/wiki-06-medi-docs-scaffold-pattern.md`. wiki 가 충족해야 할 4 책임 (R1 scaffold / R2 트리거 / R3 검증·인덱싱 / R4 메타 노출) 을 정의했고, 4 책임 모두 *project-agnostic 공용 골격* 영역이다. wiki 의 *프로젝트 의존 슬롯* (카테고리 활용 깊이·버전 라벨·도메인 어휘·카테고리 추가) 은 plugin 본문에 박지 않고 사용자 README 의 가이드 블록과 D3 경고로 처리.

plugin 매핑 가설: 4 책임 모두 [[adr-0011-base-hoisting]] §1 + [[adr-0013-hook-precedence]] §1 에 따라 `base` 단일 plugin 책임. 자산별로 ADR 갈라지면 lineage 가 끊기고 R4 같은 cross-asset 책임이 *어디에도 안 박힘* — 단일 ADR 1개로 4 자산 매핑을 묶는다.

wiki §"Open — ADR 단계로 이월" 5 항목 (R4 배치·마커 형식·cut 동기화·uninstall·진입점 메타 파일명) 은 본 ADR Decision 에서 결정한다.

## Decision

**atomic 결정**: medi-docs scaffold pattern 의 R1·R2·R3·R4 4 책임을 모두 `base` plugin 의 4 자산으로 박는다. 자산 분할 없음 (1 ADR = 1 plugin = 4 자산 묶음).

### D-1. 자산 매핑 (R → 자산 위치)

| 책임 | 자산 | 동작 요약 |
|------|------|-----------|
| **R1** scaffold | `base/medi-docs-templates/` (디렉토리) — 9 카테고리별 README + template + 루트 `_map.md.tmpl` + `CLAUDE.md.snippet` (R4 와 공유) | onboarding skill 의 첫 셋업 분기에서 dry-run → 사용자 동의 시 `medi_docs/current/` 에 복사 |
| **R2** 트리거 | `base/hooks/hooks.json` — H1 (`PostToolUse(Write\|Edit) on medi_docs/current/**`) + H2 (`SessionStart` medi_docs/ 부재 시 안내) | plugin install 시 사용자 settings.json 에 자동 등록 |
| **R3** 검증·인덱싱 | `base/skills/docs-validate/` (사용자 배포본) — frontmatter·관계 검증 + `_map.md` 자동 갱신 + cut 직전 D1 강제 | hook H1 의 호출 대상 + `/medi:version-cut` 사전 검증 의존 |
| **R4** 메타 노출 | **R1 자산 안에 통합** — `base/medi-docs-templates/CLAUDE.md.snippet` + onboarding skill 의 dry-run 흐름이 augment 단계까지 함께 동의 받음 (옵션 A) | scaffold 와 한 동의로 묶임. 새 자산·새 hook 추가 X |

### D-2. R4 옵션 A 채택 (B·C 기각)

옵션 A (templates 자산에 통합) 채택. 이유:
- 새 자산 추가 X — 자산 카운트 4→5 부풀리기 회피.
- 사용자 동의 흐름 1회 (scaffold dry-run) 에 augment 통합 → UX 단일.
- R4 의 *cross-asset 성격* (R1 의 디렉토리 외부에 영향) 을 R1 자산이 *직접* 책임 → 위치 추적 명확.
- B (별도 skill) / C (hook 재생성) 는 §Alternatives 참조.

### D-3. R4 마커 블록 형식

```
<!-- medi-docs-managed:start v={plugin_version} -->
... (자동 생성 안내 본문)
<!-- medi-docs-managed:end -->
```

- **Idempotent** — 재실행 시 마커 블록 *내부만* 갱신, 외부 사용자 내용 절대 변경 X.
- **다중 plugin 충돌 회피** — namespace prefix `medi-docs-managed`. 다른 plugin 도 augment 시 자기 namespace 사용 (예: `nexus-frontend-managed`) → 충돌 X.
- **버전 표시** — `v={plugin_version}` 으로 stale 감지 가능 (drift 발견 시 사용자 / 다음 cut 가 갱신).
- **Escape** — snippet 내 `-->` 등장 금지 (scaffold 시 검증). 사용자 본문 내 마커 동일 문자열 등장 시 conflict marker 로 안내.

### D-4. R4 cut 동기화 정책

`/medi:version-cut` 의 사전 단계 (D1 검증 직전) 에 R4 자산 재생성 끼움:
- 카테고리·skill 버전 변동을 cut 시점에 동결.
- 사용자 동의 단계 추가 X — cut 자체가 명시 호출이라 추가 동의 불필요.
- R4 재생성 실패 시 cut 차단 (D1 와 동일 wiring).

별도 명령 (`/medi:claude-md-sync`) 분리는 운영 후 수요 측정 후 결정 (Follow-up).

### D-5. R4 uninstall 정책

`base` plugin uninstall 시:
- 사용자 진입점 메타 파일 (CLAUDE.md 등) 의 `medi-docs-managed` 마커 블록 자동 제거.
- 외부 사용자 내용 보존.
- 안내 메시지: "사용자 진입점 메타 (`{path}`) 의 medi-docs 안내 섹션이 제거되었습니다. `medi_docs/` 디렉토리는 사용자 자산이라 보존됩니다."
- 마커 블록 발견 실패 시 (사용자 수동 삭제 등) 무시 + warning 로그.

### D-6. R4 진입점 메타 파일명 발견 우선순위

사용자 repo 의 *Claude 진입점 메타* 파일을 다음 순서로 발견:
1. `CLAUDE.md` (Claude Code 표준)
2. `AGENTS.md` (다른 agent 도구 호환)
3. 부재 시 `CLAUDE.md` 신규 생성 (마커 블록만 포함)

다중 발견 시 *모두 augment* (Claude·다른 agent 양쪽 인식). 사용자 settings 로 우선순위 / 대상 파일 override 는 운영 후 (Follow-up).

### D-7. R4 snippet 본문 필수 항목 (base 조각 기준)

base plugin 의 `CLAUDE.md.snippet` 은 다음 5 항목을 1-screen 으로 노출:
1. `medi_docs/` 구조 한 줄 요약 (9 카테고리 + carry-forward + lineage)
2. 진입점 안내 — "`medi_docs/planning/` 부터 읽고 `sources:` 그래프 따라"
3. **슬래시 명령 목록** — *base 명령 (`/medi:new`, `/medi:version-cut`) + 현재 설치된 다른 plugin 들의 명령 합성 (D-8 위임)*
4. hook 동작 1줄 — H1 자동 검증 발동 조건 + H2 부재 시 안내
5. `_map.md` 위치 (관계 그래프 진입)

snippet 자체는 templates 디렉토리에 박혀 sources lineage 추적 가능 (sources-04 §"노출 채널 부재" 직접 응답). **3 항목 (슬래시 목록) 은 정적 박제 X — D-8 collector 가 install 된 plugin 풍경 합성.**

### D-8. R4 cross-plugin 합성 (collector 모델)

R4 snippet 이 사용자 *전체 plugin 풍경* 을 한 마커 블록에 노출하려면 *base 가 collector 역할* 한다.

**Plugin 별 책임**:
- 각 role plugin (`backend`, `frontend`, ...) 은 자기 자산에 `CLAUDE.md.snippet` 조각 박음 — 자기 SKILL/슬래시 description 만.
  - 위치: ADR-0014 단일 plugin 모델 기준 `base/role-templates/<role>/CLAUDE.md.snippet`.
  - 형식: 1줄 슬래시 entry — `- /<command> <one-line description>`.
- base 의 R4 augmenter 가 install 된 plugin 발견 → 조각 수집 → 마커 블록 본문 합성.

**합성 규칙**:
- **순서**: base 먼저 (`/medi:new`, `/medi:version-cut`), role plugin 들은 알파벳순 (backend < frontend < infra < pm < planner < qa).
- **중복 슬래시 충돌**: warning + 첫 plugin 우선 (사용자 onboarding 출력 + R4 마커 블록 안에 conflict 코멘트 박음).
- **부재 plugin 무시**: 발견 못 한 role 은 스킵 (warning 없음).
- **재합성 트리거** (4 시점):
  1. `/medi:version-cut` 사전 단계 (D-4 와 합쳐짐).
  2. 사용자 명시 호출 — `/medi:claude-md-sync` (수동 갱신, 운영 후 도입 = Follow-up).
  3. `harness` onboarding 의 첫 셋업 (R1 scaffold 와 한 dry-run).
  4. plugin install/uninstall hook (Claude Code plugin manifest 가 지원하면 — 운영 후 검증).

**구현 위치**: `base/scripts/medi-claude-md-augment.sh` — collector + 마커 블록 박기 + idempotent 갱신. uninstall 분리 본 (`medi-claude-md-uninstall.sh`) 도 같은 위치.

**역할 분리 명세**:
| 자산 | 책임 |
|------|------|
| base/medi-docs-templates/CLAUDE.md.snippet | base 슬래시 + 구조 안내 + hook 안내 — 정적 |
| base/role-templates/<role>/CLAUDE.md.snippet | role 의 슬래시 entries — role 자체 책임으로 갱신 |
| base/scripts/medi-claude-md-augment.sh | collector — 위 둘을 합성해 사용자 CLAUDE.md 마커 블록에 박음 |

## Alternatives Considered

| 후보 | 채택 안 한 이유 |
|------|------------------|
| 공용 골격 + 프로젝트 슬롯 *합쳐서* role plugin 본문에 박기 | wiki 두 층 분리 무효화. base plugin 의 *role-generic* 의미 자기모순 (promote-docs SKILL §자산 분리 룰 §금지) |
| **자산별 별 ADR** — adr-0006 templates / adr-0007 hooks / adr-0008 skill / adr-0009 R4 | lineage 끊김 + R4 의 cross-asset 성격 표현 불가 + 4 자산이 동시 박혀야 동작하는 *책임 묶음* 본질 흐려짐 |
| **R4 옵션 B** — `base/skills/medi-docs-claude-md/` 별도 skill | 자산 카운트 5로 늘어남 + skill 추가 정당성 약함 (R4 = 일회성 + cut 시 갱신, skill 자율 호출 가치 낮음) + 사용자 동의 흐름 분리 (scaffold + augment 두 번 동의) |
| **R4 옵션 C** — H3 신설 (`PostToolUse on medi_docs/current/**` → CLAUDE.md regen) | 과도. CLAUDE.md drift 는 작고 매 Write 마다 메타 파일 재쓰기는 noise. cut 시 동기화 (D-4) 로 충분 |
| **R4 cut 동기화를 별도 명령 (`/medi:claude-md-sync`) 분리** | UX 분산. cut 자체가 *전체 동결* 시점이라 R4 도 함께 동결이 의미상 자연. 분리 명령은 수요 측정 후 (Follow-up) |
| **단일 진입점 메타 (`CLAUDE.md` 만)** | 다른 agent 도구 (AGENTS.md) 사용 사용자 누락. D-6 의 *모두 augment* 가 호환성 안전 |
| **base 가 아닌 별 plugin** (`medi-docs-plugin/`) | base 의 *모든 사용자 자동 수신* 책임 ([[adr-0011-base-hoisting]]) 와 medi_docs 가치 명제 ("플러그인 깔면 자동 점검") 직접 충돌 — base 외 위치는 의미 없음 |

## Implementation Path

| Action | 누가 | 언제 | 의존 / 산출 |
|--------|------|------|--------------|
| `base/medi-docs-templates/` 디렉토리 + 9 카테고리 README/template scaffold | harness 메인테이너 | v0.2 | 산출: 디렉토리 트리 + 루트 `_map.md.tmpl` |
| `base/medi-docs-templates/CLAUDE.md.snippet` 작성 (D-7 5 항목) | harness 메인테이너 | v0.2 | 의존: 위 디렉토리. snippet 마커 블록 escape 검증 |
| `base/hooks/hooks.json` 에 H1 + H2 등록 | harness 메인테이너 | v0.2 | 의존: spec-14 §H1·H2 명세. 산출: plugin install 시 settings.json 자동 등록 |
| `base/skills/docs-validate/` 사용자 배포본 작성 | harness 메인테이너 | v0.2 | 의존: spec-12 §50·§94·§98-106. 메인테이너용 `.claude/skills/docs-validate` 와 분리 |
| `harness` onboarding skill 의 첫 셋업 분기에 *dry-run augment 단계* 추가 (R1 + R4 한 동의) | harness 메인테이너 | v0.2 | 의존: 위 4 자산. dry-run 메시지에 "+ CLAUDE.md 안내 섹션 추가 (마커 블록)" 추가 |
| `base/scripts/medi-claude-md-augment.sh` (D-8 collector) — install plugin 발견 + snippet 조각 합성 + 마커 블록 박기 | harness 메인테이너 | v0.2 | 의존: D-8 합성 규칙 + D-3 마커 형식. idempotent |
| `base/scripts/medi-claude-md-uninstall.sh` (D-5 분리 본) — 마커 블록 제거 + 안내 | harness 메인테이너 | v0.2 | base uninstall hook 가 호출 |
| 각 role plugin (backend, frontend, ...) 의 `role-templates/<role>/CLAUDE.md.snippet` 조각 작성 책임을 해당 plugin ADR 의 Implementation Path 에 추가 | 각 role 메인테이너 | role 별 plugin 첫 패키징 | adr-0001~005 (backend) 의 Notes 에 cross-ref 추가 |
| `/medi:version-cut` 의 사전 단계에 R4 재생성 끼움 (D-4) | harness 메인테이너 | v0.2 | 의존: D1 검증 wiring + D-8 collector. R4 실패 시 cut 차단 |
| `base` plugin uninstall hook 에 R4 마커 블록 제거 + 안내 메시지 (D-5) | harness 메인테이너 | v0.2 | 의존: 마커 형식 D-3 |
| 진입점 메타 발견 로직 (D-6 우선순위) 구현 | harness 메인테이너 | v0.2 | onboarding skill + cut 시 동기화 양쪽에서 호출 |
| 검증 — 4 자산 모두 박힌 후 *플러그인 깔면 정형 docs + 자동 점검* 가치 명제 end-to-end 시연 | harness 메인테이너 | v0.2 cut 직전 | 의존: 모든 위 액션 완료 |

## Consequences

**Pros**
- *플러그인 깔면 정형화된 문서 구조 + Claude 가 즉시 인식* — adr-0008 의 가치 명제가 처음으로 *Claude 측 인식* 까지 완전 충족.
- 4 책임이 *한 plugin 의 4 자산* 으로 묶여 lineage 추적 명확. 자산 누락 시 즉시 식별.
- R4 옵션 A 로 사용자 동의 흐름 단일 (scaffold + augment 한 dry-run).
- 마커 블록으로 사용자 기존 CLAUDE.md 보존 + 다중 plugin 충돌 회피 + 버전 stale 감지 가능.
- cut 시점 R4 동기화로 카테고리·skill 변동 자동 반영.

**Cons**
- 4 자산 동시 유지 책임 — 하나만 stale 해도 가치 명제 부분 깨짐. 메인테이너 자기 규율 의존.
- R4 의 진입점 메타 augment 가 사용자 repo 외부 파일 (CLAUDE.md) 침범 — 마커 블록·dry-run·uninstall 정책으로 완화하지만 *완전 무침범* 은 아님.
- R4 snippet 이 정적 텍스트라 사용자가 skill 추가/제거 시 drift. cut 시 동기화로 완화하지만 cut 사이 기간은 stale.
- `AGENTS.md` 도 augment (D-6 다중) 시 두 파일 일관성 책임 — 둘 중 하나만 사용자 수정 시 drift 가능.

**Follow-ups**
- [ ] `/medi:claude-md-sync` 명시 명령 도입 — D-8 재합성 트리거 4종 중 (2). cut 사이 drift 실제 문제로 떠오르면.
- [ ] R4 snippet 본문의 SKILL/슬래시 자동 introspection vs 각 plugin 의 정적 snippet 조각 — 현재 후자 채택 (D-8). 운영 후 introspection 갈지 재검토.
- [ ] 진입점 메타 파일명 사용자 settings override 도입 (`harness.entryMeta: ["AGENTS.md", "CLAUDE.md"]`).
- [ ] 다중 plugin augment 시 마커 블록 순서·간격 컨벤션 — D-8 알파벳순 채택. 사용자 override 수요 측정.
- [ ] cut 시 R4 재생성 실패의 *우회 옵션* (`--skip-meta-sync`) 도입 여부 — 운영 후 결정.
- [ ] Claude Code plugin manifest 의 install/uninstall hook 어휘 조사 → D-8 재합성 트리거 4 (plugin install/uninstall 시) 정식 wiring 검증.
- [ ] 슬래시 충돌 시 conflict 코멘트 wording 표준화 (사용자 가이드 + 자동 처리 분기).

## Notes

- 2026-05-01: status proposed. wiki-06 §"Open — ADR 단계로 이월" 5 항목을 모두 D-2~D-6 으로 결정. R4 옵션 A 채택. 4 자산 묶음 단일 ADR 패턴 (자산별 분할 X).
- 2026-05-01: D-7 보강 + D-8 신설 — *cross-plugin R4 합성*. 사용자 시각 (CLAUDE.md 마커 블록에 *현재 설치 plugin 풍경 전체* 노출) 갭 발견 후 collector 모델 (base 가 합성 책임, 각 role plugin 이 자기 snippet 조각 제공) 채택. Implementation Path 에 collector + uninstall + role snippet 작성 책임 3 액션 추가. Follow-ups 2종 추가.
- 2026-05-01: applied to plugin `base` (content/harness/plugins/base/). 4 책임 자산 입주 — R1 (medi-docs-templates/9 카테고리 + _map.md.tmpl), R2 (hooks/hooks.json H1 path_filter 추가 + H2 SessionStart medi-scaffold-check.sh), R3 (scripts/medi-validate.sh — frontmatter D1 + sources D4 + _map.md 자동 갱신), R4 (medi-docs-templates/CLAUDE.md.snippet + scripts/medi-claude-md-augment.sh collector + role-templates/<role>/CLAUDE.md.snippet 7 placeholder, backend 만 5 슬래시 박음). 슬래시 명령 2종 (commands/medi-new.md, commands/medi-version-cut.md) + 동작 sh (medi-new.sh, medi-version-cut.sh) + uninstall sh (medi-claude-md-uninstall.sh). scaffold-medi-docs.sh 끝에 R4 augment 자동 호출 wiring 추가. /tmp/medi-docs-smoke 에서 end-to-end 검증 완료 (scaffold → augment 본문 보존 + 6 슬래시 합성 → new → validate D4 → cut R4+D1+박제+chmod a-w → uninstall 마커 제거 + 본문 보존). bash 3.2 호환 (assoc array / globstar 회피).
