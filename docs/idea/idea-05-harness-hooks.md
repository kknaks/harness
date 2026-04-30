---
id: idea-05
type: idea
status: absorbed
created: 2026-04-29
tags: [idea]
---

# Harness Hooks

harness plugin 이 사용자에게 배포할 hooks 자산이 필요하다. 현재 메인테이너용 hook 1개 (`PostToolUse` → docs-validate, harness 메타 docs 변경 시) 만 있고, 사용자 medi_docs 변경에 트리거되는 hook 은 없다. plugin 의 핵심 가치 ("플러그인 깔면 정형화된 문서 구조 + 자동 검증") 가 반쪽이다.

## 핵심 제약

- **자동 등록**: plugin install 시 사용자 settings.json 에 hook 이 *추가* 되어야 함 (덮어쓰기·수동 편집 X). uninstall 시 제거.
- **사용자 통제권 보존**: 사용자가 hook 을 끌 수 있어야 함 ([[adr-0006-onboarding-skill]] 의 *사용자 통제권* 원칙 평행). plugin manifest 에 default on/off 명시.
- **레이어 분리**: 메인테이너용 hook (harness repo `docs/` 변경 트리거) 과 사용자 배포 hook (user repo `medi_docs/` 변경 트리거) 분리. 한 환경에 둘이 동시 등록되지 않음.
- **authoring 규칙**: hook 정의도 [[idea-04-skill-authoring-rules]] 의 화이트리스트·보안 정책 따라야 함 (`allowed_tools`, `allow_commands`, 입력 sanitize).

## 후보 hook 셋

| # | hook | 트리거 | 동작 |
|---|------|-------|------|
| H1 | medi_docs 자동 검증 | `PostToolUse` (Write\|Edit) on `medi_docs/current/**` | `docs-validate` 사용자 배포본 실행 (D1, D4 등 룰셋). 위반 시 즉시 경고 |
| H2 | scaffold 부재 안내 | `SessionStart` | `medi_docs/` 부재 + 사용자 새 세션이면 `harness` skill 안내 메시지 |
| H3 | version-cut 사전 검증 | `UserPromptSubmit` 또는 사전 훅 | `/medi:version-cut` 호출 직전 D1 사전 검증 결과 미리 알림 |

## 핵심 발상

- **hooks = plugin 자산** — skills 와 동일하게 plugin manifest 에 선언. install/uninstall 자동 등록·해제. base plugin 안에 패키징 ([[spec-06-base-hoisting]]).
- **트리거 경로 한정** — hook 발동 조건을 `medi_docs/current/**` 같은 경로 패턴으로 한정 → harness 가 사용자의 다른 작업에 끼어들지 않음.
- **공유 룰셋** — H1 의 검증 룰은 [[spec-12-medi-docs-tooling]] 의 `docs-validate` 사용자 배포본 그대로 호출. hook 은 *언제 호출하는지* 만 결정, *무엇을 검증하는지* 는 spec-12 위임.

## Open Questions

- [ ] (a) plugin install → settings.json 자동 등록 메커니즘 — Claude Code plugin manifest 가 hook 을 어떻게 박나? 사용자 동의 분기 필요?
- [ ] (b) 사용자 disable 인터페이스 — `/harness:hook off H1` 같은 슬래시? settings.json 직접 편집? plugin 설정?
- [ ] (c) 첫 출시 hook 셋 — H1 만 시작 (YAGNI), 또는 H1+H2 (사용자 onboarding 지원), 또는 셋 다?
- [ ] (d) hook 자체의 frontmatter 스키마 — skill 처럼 `allowed_tools`/`allow_commands` 가지나, hook 은 별도 어휘 필요한가?

## spec 분기

단일 spec 권장: **`harness-hooks`** — 자산 패키징 + 기본 hook 셋 (H1 우선) + authoring 규칙 + install/disable 동작. 토픽 응집도 높음.

대안: hook 셋 (H1/H2/H3) 따로 spec 으로 쪼갬 — H1 만 v0.1 필수, 나머지는 후순위라 인위적 분리. 1 spec 권장.

## 관련

- [[idea-04-skill-authoring-rules]] — authoring 규칙 평행 (skills ↔ hooks).
- [[spec-06-base-hoisting]] — plugin 자산 패키징 위치.
- [[spec-12-medi-docs-tooling]] — H1 이 호출하는 `docs-validate` 사용자 배포본.
- [[adr-0008-medi-docs-scaffold]] — D1-D4 강제 룰의 검증 시점 (hook 이 발동 시점).
