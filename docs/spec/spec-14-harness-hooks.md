---
id: spec-14
title: Harness Hooks
type: spec
status: accepted
created: 2026-04-29
updated: 2026-04-29
sources:
  - "[[idea-05-harness-hooks]]"
owns: harness-hooks
tags: [spec]
aliases: []
related_to:
  - "[[spec-12-medi-docs-tooling]]"
  - "[[spec-13-skill-authoring-rules]]"
  - "[[adr-0008-medi-docs-scaffold]]"
  - "[[adr-0009-harness-hooks]]"
depends_on:
  - "[[spec-06-base-hoisting]]"
---

# Harness Hooks

## Scope

harness plugin 이 사용자에게 배포하는 hooks 자산 — 첫 출시 hook 셋, plugin manifest 기반 자동 등록·해제, 사용자 disable 인터페이스, hook authoring 규칙. 메인테이너용 hook (harness repo `.claude/`) 은 별개.

## Summary

plugin install 시 사용자 settings.json 에 자동 등록되어 `medi_docs/current/**` 변경에 발동하는 hook 자산 정책을 정의한다. 첫 출시 = H1 (medi_docs 자동 검증 필수) + H2 (scaffold 부재 안내, 권장). H3 (version-cut 사전 검증) 후순위. authoring 규칙은 [[spec-13-skill-authoring-rules]] 평행.

## Background

(원본: [[idea-05-harness-hooks]])

harness 의 핵심 가치 = "플러그인 깔면 정형화된 문서 구조 + 자동 검증". 현재 PostToolUse hook 1개 (메타 `docs/` 변경 시 docs-validate) 만 있고 사용자 medi_docs 변경 트리거가 없어 가치 명제가 반쪽이다.

레이어 분리 ([[idea-02-mediness-architecture]] 권한 모델):
- **메인테이너 hook** — harness repo 의 `docs/idea` `docs/spec` 변경 트리거. harness 메인테이너 환경에만 등록.
- **사용자 hook (이 spec)** — user repo 의 `medi_docs/current/**` 변경 트리거. plugin install 시 사용자 환경 자동 등록.

## Goals

- 사용자 medi_docs 변경 시 자동 검증 ([[adr-0008-medi-docs-scaffold]] §6 D1·D4 룰셋 즉시 적용).
- plugin install/uninstall 시 hook 자동 등록·해제. 사용자 settings.json 수동 편집 X.
- 사용자 disable 인터페이스 제공. plugin 통제권 보존 ([[adr-0006-onboarding-skill]] 평행 원칙).
- hook authoring 규칙을 skill 과 평행 (allowed_tools, allow_commands, sanitize).
- 첫 출시 셋 최소화 — H1 필수, H2 권장, H3 deferred.

## Non-goals

- 메인테이너 hook (harness repo 자체 관리) — 별개.
- hook 이 호출하는 검증 로직 자체 → [[spec-12-medi-docs-tooling]].
- hook authoring 검증 도구 — [[spec-13-skill-authoring-rules]] 가 평행 적용 (별도 도구 X).
- MCP 서버 자산 → [[idea-06-harness-mcp]] (spec-15).

## Design

### 첫 출시 hook 셋 (D1)

| hook | 트리거 | 동작 | v0.1 |
|------|-------|------|------|
| **H1** medi_docs 자동 검증 | `PostToolUse` (Write\|Edit) on `medi_docs/current/**` | `docs-validate` 사용자 배포본 실행. D1·D4 위반 즉시 경고 | **필수** |
| **H2** scaffold 부재 안내 | `SessionStart` (medi_docs/ 부재 시) | `harness` skill 안내 메시지 출력 | 권장 |
| **H3** version-cut 사전 검증 | (사전 훅) `/medi:version-cut` 호출 직전 | D1 사전 검증 결과 미리 알림 | M2 후순위 |

### plugin manifest 자동 등록 (D2)

Claude Code plugin 시스템 사용 — 사용자 `settings.json` 직접 편집 X.

1. harness plugin 의 `plugin.json` 또는 `hooks/hooks.json` 에 hook 선언.
2. 사용자가 `claude plugin install harness` 후 `enable` 하면 plugin 의 hooks 가 자동 활성화.
3. 사용자 `settings.json` 에는 `enabledPlugins` 항목만 추가됨 — hook entry 직접 들어가지 않음.
4. uninstall/disable 시 plugin 의 hooks 자동 비활성화.

이 모델 덕분에 *충돌 처리* 가 사실상 불필요 — plugin hook 과 사용자 직접 hook 은 namespace 가 분리됨 (plugin enable 여부로 갈림).

### 사용자 disable 인터페이스 (D3)

Claude Code 가 *개별 hook* `disabled: true` native 미지원. 대안 두 갈래:

| 입도 | 메커니즘 | 명령 |
|------|----------|------|
| **plugin 전체** | Claude Code native | `/plugin disable harness` (재활성: `/plugin enable harness`) |
| **개별 hook** | manifest condition + env var | hook 정의에 `condition: "${HARNESS_HOOK_<ID>_ENABLED:-true}"`. 사용자가 env var 로 끔 |

추가 슬래시 `/harness:hook list` 는 plugin 자체 skill 로 제공 (현재 등록된 harness hook 목록 + env var 상태 출력).

전체 비활성화는 `disableAllHooks: true` (settings.json 최상위) 도 가능하지만 *모든 hook* 영향 → 권장 X.

### 트리거 경로 한정 (D4)

hook 발동 조건을 `medi_docs/current/**` 패턴으로 한정. 사용자의 다른 작업 (코드, 다른 docs/) 에 절대 끼어들지 않음. 박제된 `v{label}/` 는 read-only 라 트리거 안 함.

### authoring 규칙 (D5)

[[spec-13-skill-authoring-rules]] 어휘를 hook frontmatter 에 평행 적용:

| 필드 | 의미 | 강제 |
|------|------|------|
| `allowed_tools` | hook script 가 호출 가능한 tool 화이트리스트 | 차단 (필드 누락 시) |
| `allow_commands` | 위험 명령 (rm, git push 등) 화이트리스트 | 차단 (외부 명령 시) |
| 입력 sanitize | 트리거 컨텍스트 (file path, prompt) 직접 셸 삽입 금지 | 코드 리뷰 |

## Interface

### plugin `hooks/hooks.json` (예시)

Claude Code 공식 어휘 (`event`, `matcher`, `hooks[].type`, `hooks[].command`) + plugin 변수 (`${CLAUDE_PLUGIN_ROOT}`):

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/scripts/medi-validate.sh",
        "condition": "${HARNESS_HOOK_H1_ENABLED:-true}",
        "path_filter": "medi_docs/current/**"
      }]
    }],
    "SessionStart": [{
      "hooks": [{
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/scripts/scaffold-prompt.sh",
        "condition": "${HARNESS_HOOK_H2_ENABLED:-true}"
      }]
    }]
  }
}
```

(`path_filter` 는 harness 자체 wrapper script 안에서 필터링 — Claude Code native 필드 아님.)

### 슬래시 커맨드 (harness plugin 자체 제공)

- `/harness:hook list` — 등록된 harness hook + env var 활성 상태 출력.

plugin 단위 on/off 는 Claude Code native `/plugin enable|disable harness` 그대로 사용 (재정의 X).

## Alternatives Considered

- **사용자 settings.json 직접 편집** — 자율성 ↑, 학습 비용 ↑·자동 검증 즉시 X·plugin 가치 ↓. 채택 X.
- **install hook 강제 등록 + 끄기 X** — 단순하지만 사용자 통제권 침범. 채택 X.
- **첫 출시 H1+H2+H3 모두** — 운영 패턴 모른 채 셋 다 박는 건 YAGNI. H1 필수 + H2 권장 + H3 deferred 가 균형.
- **충돌 entry 자동 병합** — 사용자 의도 침범 위험. 동의 분기가 안전.

## Open Questions

- [x] (D2.a) Claude Code plugin manifest 의 hook 등록 스펙 — **확인 (2026-04-29)**: `plugin.json` 또는 `hooks/hooks.json` 에서 선언 가능. 필드 어휘 = `event` 키 (`PostToolUse` 등) + `matcher` + `hooks[].type` (`command`/`http`/`mcp_tool`/`prompt`/`agent`) + `command`. plugin enable 시 활성화, 사용자 settings.json 에는 `enabledPlugins` 만 추가됨. 충돌 처리는 namespace 분리로 사실상 불필요. 출처: code.claude.com/docs/en/plugins.md, plugins-reference.md.
- [x] (D3.b) `disabled: true` 플래그 native 지원 — **확인 (2026-04-29)**: native 미지원. settings.json 최상위 `disableAllHooks: true` 만 native 제공 (개별 hook 영향 X). 개별 disable 은 (a) plugin 단위 `/plugin disable harness`, 또는 (b) manifest condition + env var 조합으로 우회. 출처: code.claude.com/docs/en/hooks.md.
- [ ] (D5.c) hook authoring 룰을 [[spec-13-skill-authoring-rules]] 에 흡수할지 (multi-target: skill + hook), 별도 spec 으로 분리할지 — 평행 적용으로 명시했으나 spec-13 확장 더 자연스러울 수 있음. 운영 후 결정.
