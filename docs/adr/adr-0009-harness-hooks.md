---
id: adr-0009
title: Harness Hooks
type: adr
status: accepted
date: 2026-04-29
sources:
  - "[[spec-14-harness-hooks]]"
tags: [adr]
aliases: []
depends_on:
  - "[[adr-0008-medi-docs-scaffold]]"
  - "[[adr-0013-hook-precedence]]"
related_to:
  - "[[adr-0007-skill-authoring-rules]]"
  - "[[adr-0010-harness-mcp]]"
---

# Harness Hooks

## Context

(승격 원본: `docs/spec/spec-14-harness-hooks.md`)

harness plugin 의 핵심 가치 = "플러그인 깔면 정형화된 문서 구조 + 자동 검증" ([[adr-0008-medi-docs-scaffold]]). 현재 PostToolUse hook 1개 (메타 docs 변경 시 docs-validate) 만 있어 사용자 medi_docs 변경에 트리거되는 hook 이 부재 — 가치 명제가 반쪽이다.

레이어 분리 (idea-02 권한 모델):

| 레이어 | 트리거 | 등록 시점 |
|--------|--------|-----------|
| 메인테이너 hook | harness repo `docs/` 변경 | harness 메인테이너 환경 자체 관리 (이 ADR 대상 X) |
| **사용자 hook (이 ADR)** | user repo `medi_docs/current/**` 변경 | plugin install 시 자동 활성화 |

[[adr-0008-medi-docs-scaffold]] §6 D1·D4 강제 룰을 *언제* 검증할지가 medi_docs hook 의 핵심 책임. 그 외 base plugin 이 책임지기로 박은 보안·환경 hook ([[adr-0013-hook-precedence]] §1) 도 첫 출시 셋에 함께 포함한다.

## Decision

### 1. 첫 출시 hook 셋

**Host plugin** = `base/hooks/hooks.json` ([[adr-0013-hook-precedence]] §1 책임 분리 — 보안·환경·medi_docs 알림 hook 모두 base 책임). v0.1 시점 `base` 가 모든 role plugin 의존이라 모든 사용자가 즉시 받음.


| hook | 트리거 | 동작 | v0.1 |
|------|-------|------|------|
| **H1** medi_docs 자동 검증 | `PostToolUse` (Write\|Edit) on `medi_docs/current/**` | docs-validate 사용자 배포본 실행. D1·D4 위반 즉시 경고 | **필수** |
| **H2** scaffold 부재 안내 | `SessionStart` (medi_docs/ 부재 시) | `harness` skill 안내 메시지 | 권장 |
| **H3** version-cut 사전 검증 | (사전 훅) `/medi:version-cut` 호출 직전 | D1 사전 검증 결과 미리 알림 | M2 후순위 |
| **H4** 시크릿 차단 | `PreToolUse` (Write\|Edit) | 변경 파일이 시크릿 패턴 (`.env`, `*.pem`, `*.key`, `secrets/**`) 매칭 시 `permissionDecision: "deny"` | **필수** |
| **H5** 환경 검증 | `SessionStart` | 사용자 환경 의존성 (Docker / Node) 부재 시 안내 메시지 출력 (block X — 안내만) | **필수** |

### 2. 등록 모델 — Claude Code plugin 활성화

plugin 의 `plugin.json` 또는 `hooks/hooks.json` 에 hook 선언 → plugin enable 시 활성화. 사용자 settings.json 에 `enabledPlugins` 만 추가됨, hook entry 직접 편집 X. plugin uninstall 시 자동 비활성. 충돌 처리는 namespace 분리로 사실상 불필요.

### 3. Disable 인터페이스

| 입도 | 메커니즘 | 명령 |
|------|----------|------|
| **plugin 전체** | Claude Code native | `/plugin disable harness` |
| **개별 hook** | manifest condition + env var | `condition: "${HARNESS_HOOK_<ID>_ENABLED:-true}"` |

(Claude Code 가 *개별 hook* `disabled: true` 플래그 native 미지원. `disableAllHooks: true` 는 *모든* hook 영향 → 권장 X.)

### 4. 트리거 경로 한정

`medi_docs/current/**` 패턴으로 한정. 박제된 `v{label}/` 는 read-only 라 트리거 안 함. 사용자의 다른 작업·docs 에 절대 끼어들지 않음. (`path_filter` 는 wrapper script 내부 책임 — Claude Code native 필드 아님.)

### 5. Authoring 규칙

[[adr-0007-skill-authoring-rules]] 어휘를 hook frontmatter 에 평행 적용:

| 필드 | 의미 | 강제 |
|------|------|------|
| `allowed_tools` | hook script 호출 가능 tool 화이트리스트 | 차단 (필드 누락 시) |
| `allow_commands` | 위험 명령 화이트리스트 | 차단 (외부 명령 시) |
| 입력 sanitize | 트리거 컨텍스트 직접 셸 삽입 금지 | 코드 리뷰 |

## Alternatives Considered

| 후보 | 채택 안 한 이유 |
|------|------------------|
| 사용자 settings.json 직접 편집 | 학습 비용 ↑, 자동 검증 즉시 X. plugin 가치 ↓ |
| install hook 강제 등록 + 끄기 X | 사용자 통제권 침범 |
| 첫 출시 H1+H2+H3 모두 | 운영 패턴 모르는 채 박는 건 YAGNI |
| 충돌 entry 자동 병합 | 사용자 의도 침범 위험 |

## Implementation Path

| Action | 누가 | 언제 | 의존 |
|--------|------|------|------|
| `base/hooks/hooks.json` 작성 (H1·H4·H5 우선) | 메인테이너 | v0.1 release 전 | [[spec-12-medi-docs-tooling]], [[adr-0013-hook-precedence]] |
| H1 trigger script (`medi-validate.sh`) — docs-validate 사용자 배포본 호출 | 메인테이너 | spec-12 구현 후 | docs-validate 배포본 |
| H4 trigger script (`secret-guard.sh`) — 시크릿 패턴 grep + deny | 메인테이너 | v0.1 release 전 | — |
| H5 trigger script (`env-check.sh`) — Docker/Node 부재 시 안내 | 메인테이너 | v0.1 release 전 | — |
| `/harness:hook list` skill | 메인테이너 | v0.1 | — |
| H2 (scaffold 부재 안내) onboarding skill 통합 | 메인테이너 | v0.1 | [[adr-0006-onboarding-skill]] |
| H3 deferred | — | M2+ | 운영 후 결정 |

## Consequences

**Pros**
- *플러그인 깔면 자동 검증* — harness 핵심 가치 명제 완성.
- 메인테이너·사용자 hook 분리 → 한 환경에 둘 동시 등록 X.
- plugin 단위 disable + env var 개별 제어 → 사용자 통제권 보존.
- authoring 규칙 [[adr-0007]] 평행 → 보안 정책 일관.

**Cons**
- 개별 hook `disabled: true` native 미지원 → env var condition 우회 의존, 사용자 설명 필요.
- plugin manifest 의 hook 충돌 처리 공식 미문서화 → 운영 중 발견 시 대응.
- trigger 경로 (`medi_docs/current/**`) 의 wrapper 필터링 native 필드 X — script 내부 책임.

**Follow-ups**
- [ ] H3 (version-cut 사전 검증) 운영 후 도입 여부.
- [ ] Hook authoring 룰을 [[adr-0007]] 에 흡수할지 — multi-target 검증 일관성 vs 별도 spec 분리 (spec-14 D5.c 살아있음).
- [ ] env var condition 우회 패턴이 사용자에게 직관적인지 — 운영 중 검증.
- [ ] H4 시크릿 패턴 확장 — `.env/*.pem/*.key/secrets/**` 외 (`kubeconfig`, `.aws/credentials`, `id_rsa` 등) 운영 중 추가.
- [ ] H5 환경 의존성 목록 확장 — Docker/Node 외 (Python, kubectl, gcloud 등) 운영 중 추가. role plugin 별 환경 검증으로 분리할지 ([[adr-0013-hook-precedence]] §1 책임 분리 재검토).

## Notes

- 2026-04-29: [[spec-14-harness-hooks]] → ADR 승격. 외부 조사로 plugin manifest hook 스펙 + `disabled` 플래그 native 미지원 확인 후 design 박제. spec-14 status accepted 유지.
- 2026-04-29: 정합성 검증 후 §1 hook 셋에 H4 (시크릿 차단) + H5 (환경 검증) 추가. [[adr-0013-hook-precedence]] §1 가 base 책임으로 박은 보안·환경 카테고리가 §1 enum 에 누락되어 있던 갭 해소. 첫 출시 필수 = H1+H4+H5 3 종.
