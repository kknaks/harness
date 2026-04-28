---
id: spec-13
title: Skill Authoring Rules
type: spec
status: draft
created: 2026-04-28
updated: 2026-04-28
sources:
  - "[[idea-04-skill-authoring-rules]]"
owns: skill-authoring-rules
tags: [spec]
aliases: []
related_to:
  - "[[spec-03-frontmatter-naming]]"
  - "[[spec-11-medi-docs-frontmatter]]"
---

# Skill Authoring Rules

## Scope

`.claude/skills/*/SKILL.md` 의 frontmatter 스키마 + 본문 규칙 + 보안 정책 + 검증 룰셋. 메타·콘텐츠 docs (`docs/idea`, `docs/spec`, `docs/adr`) 의 frontmatter 는 [[spec-03-frontmatter-naming]] 가 다룸 — 검증 대상이 다름.

## Summary

각 팀이 자유롭게 작성하는 SKILL.md 의 구조·보안·도구 접근을 6개 차원(본문 길이 / tools 화이트리스트 / context 구조화 / 보안 정책 / 동적 입력 검증 / 위반 검증)으로 표준화하고, `docs-validate` 일반화를 통해 자동 검증한다.

## Background

각 팀이 제각각 스킬을 만들면 보안·일관성이 무너진다는 문제의식에서 출발한다 (idea-04). 어떤 스킬이 어떤 도구를 호출하는지, 어떤 파일·환경변수를 읽는지, 어떤 외부 명령을 실행하는지가 묵시적으로 남으면 감사·리뷰가 불가능하다. 이 spec 은 메인테이너 도구 영역에 속하며 ([[idea-02]] 권한 모델 참조), idea-03 의 `docs-validate` 일반화 결정(Q4)의 연장선으로 한 도구가 `docs/` + `.claude/skills/` 를 동시에 검증하는 방향을 채택했다.

## Goals

- SKILL.md frontmatter 에 `allowed_tools` (필수) 와 `allow_commands` (위험 동작 한정 필수) 를 선언하게 하여 도구·명령 접근을 명시적으로 표면화한다.
- `reads_files` / `runs_scripts` / `env_vars` 선택 필드로 스킬의 컨텍스트 의존성을 구조화된 형태로 기록한다.
- 본문 길이 500자 가이드와 보안·동적 입력 지침으로 본문 품질 기준을 제시한다.
- `docs-validate` 를 일반화하여 기존 idea/spec/adr 검증과 SKILL.md 룰셋 검증을 단일 도구로 처리한다.

## Non-goals

- 메타·콘텐츠 docs frontmatter 규칙 → [[spec-03-frontmatter-naming]]
- 사용자 측 medi_docs frontmatter → [[spec-11-medi-docs-frontmatter]]
- 검증 도구 자체의 인터페이스·동작 → [[spec-12-medi-docs-tooling]] 의 사용자 배포본 명세
- 단계 간 승격 스킬 (`promote-docs`) 의 동작 → [[spec-05-promote-skills]]
- 사용자 onboarding 스킬 (`harness`) → [[spec-07-onboarding-skill]]

## Design

### frontmatter 필드 표

| 필드 | 필수/선택 | 형식 | 강제 수준 | 설명 |
|------|-----------|------|-----------|------|
| `allowed_tools` | **필수** | `[Read, Edit, Bash, ...]` | **차단** (누락 시) | Claude Code subagent 의 `tools` 패턴 재사용. 호출 가능한 도구 전체 목록 |
| `allow_commands` | 위험 동작 한정 필수 | `[git push, rm, curl, ...]` | **차단** (화이트리스트 외 명령 호출 시) | 미선언 시 안전 명령만 허용으로 간주 |
| `reads_files` | 선택 | 위키링크 리스트 | 권장 | 스킬이 읽는 파일 경로 선언 |
| `runs_scripts` | 선택 | 위키링크 리스트 | 권장 | 스킬이 실행하는 스크립트 선언 |
| `env_vars` | 선택 | 리스트 | 권장 | 스킬이 참조하는 환경변수 선언 |

`reads_files` / `runs_scripts` / `env_vars` 는 현재 권장 수준이며, 운영 후 강제 전환 여부를 별도 검토한다.

### 본문 규칙 표

| 규칙 | 측정 방식 | 강제 수준 | 비고 |
|------|-----------|-----------|------|
| 본문 길이 500자 내외 | frontmatter 제외, unicode codepoint, 코드블록 포함. `validate.py` 의 long-body 패턴 재사용 | **soft 경고** (차단 X) | 초과 시 `scripts/`, `examples/`, 별도 reference 로 분리 권장 |
| 보안 가이드 | 본문에 외부 명령 화이트리스트 이유, 금지 동작(`.env`/`secrets/` 읽기, 임의 URL fetch 등) 명시 | 가이드 (강제 X) | 모든 스킬 공통 적용 |
| 동적 입력 가이드 | 사용자 인자·외부 응답을 직접 셸/경로/프롬프트에 삽입 금지. `sanitize.sh` 헬퍼 사용 권장 명시 | 가이드. 위반은 코드 리뷰 | 헬퍼 사용 강제 X |

### 검증 차등 표 (룰셋)

| 결정 # | 대상 | 검증 레벨 | 트리거 |
|--------|------|-----------|--------|
| #2 `allowed_tools` | SKILL.md frontmatter | **차단** | 필드 누락 |
| #3 context 필드 | SKILL.md frontmatter | 경고 (권장) | 필드 미선언 |
| #4 `allow_commands` | SKILL.md frontmatter + 명령 호출 | **차단** | 화이트리스트 외 명령 |
| #5 동적 입력 | 본문 가이드 | 가이드 (코드 리뷰) | 자동 검출 불가 |
| #1 본문 길이 | SKILL.md 본문 | soft 경고 | 500자 초과 |

### `validate.py` 일반화 방향

기존 `docs-validate` 는 `docs/idea`, `docs/spec`, `docs/adr` 를 대상으로 한다. 이를 multi-target 으로 확장하여 `.claude/skills/*/SKILL.md` 도 동시에 처리한다. SKILL.md 전용 룰셋(위 표)을 별도 모듈로 추가하되, 도구 진입점은 단일(`docs-validate`)로 유지한다.

### `scripts/sanitize.sh` 헬퍼 책임 범위

공용 헬퍼로 `.claude/skills/scripts/sanitize.sh` (또는 함수 라이브러리) 를 제공한다. 헬퍼의 책임:

- 인자 검증: 허용 문자 집합, 최대 길이 확인
- 슬러그화: 공백·특수문자 제거 및 정규화
- 셸 인용: `printf '%q'` 패턴으로 인젝션 방지

헬퍼 사용은 강제하지 않으며, 본문 가이드에서 사용을 권장하는 방식으로 노출한다.

## Interface

### SKILL.md frontmatter 형식 (YAML)

기존 SKILL.md 의 `name` / `description` 에 idea-04 결정 5개 필드를 추가한다.

```yaml
---
name: <skill-slug>                      # 기존 공통 필드
description: <스킬 한 줄 설명>           # 기존 공통 필드
allowed_tools: [Read, Edit, Bash]       # 필수. 호출 가능한 도구 목록
allow_commands: [git push, rm -rf]      # 위험 명령 사용 시 필수. 미선언 = 안전 명령만
reads_files:                            # 선택
  - "[[docs/_map.md]]"
runs_scripts:                           # 선택
  - "[[scripts/validate.py]]"
env_vars:                               # 선택
  - HARNESS_ROOT
---
```

### SKILL.md 본문 스켈레톤

idea-04 의 참고 사항 (기존 스킬에서 추출 가능한 컨벤션) 에 따른 최소 구조:

```markdown
# <Skill Title>

<스킬이 하는 일 1~2문장. 500자 이내>

## 보안 고려사항

- `allow_commands` 선언 이유: ...
- 접근 금지 경로·동작: `.env`, `secrets/` 읽기 금지 등
- 동적 입력: sanitize.sh 사용 또는 직접 인용 규칙 준수
```

## Open Questions

- [ ] `reads_files` / `runs_scripts` / `env_vars` 권장 → 강제 전환 시점: 운영 기간·위반 사례 누적 후 결정.
- [ ] `allow_commands` 화이트리스트 추가 기준: 어떤 명령이 "위험"으로 분류되는지 명시적 기준 필요 (현재 `rm`, `curl`, `git push` 등 예시만 있음).
- [ ] `sanitize.sh` 단일 파일 vs. 함수 라이브러리 형태: 스킬별 소스 방식 결정 필요.
- [ ] `validate.py` 일반화 시 SKILL.md 타깃 추가가 기존 docs 검증 성능에 영향을 주는지 확인 필요.

## Alternatives Considered

- **3 spec 분할** (`skill-frontmatter-schema` / `skill-security-policy` / `skill-body-rules`): `allow_commands` 같은 필드가 보안과 frontmatter 양쪽에 걸쳐 인위적 분리가 발생. 1 spec 통합을 채택.
- **별도 검증 도구 신설**: idea-03 의 `docs-validate` 일반화 결정과 중복되고 운영 복잡도를 높임. `docs-validate` multi-target 확장을 채택.
