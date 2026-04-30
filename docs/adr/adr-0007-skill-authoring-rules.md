---
id: adr-0007
title: Skill Authoring Rules
type: adr
status: accepted
date: 2026-04-29
sources:
  - "[[spec-13-skill-authoring-rules]]"
tags: [adr]
aliases: []
depends_on:
  - "[[adr-0001-directory-structure]]"
  - "[[adr-0004-frontmatter-naming]]"
related_to:
  - "[[adr-0003-content-pipeline]]"
---

# Skill Authoring Rules

## Context

(승격 원본: `docs/spec/spec-13-skill-authoring-rules.md`)

mediness 의 *skill* 은 두 영역 모두에 존재한다.

- **메인테이너 도구** (`.claude/skills/*`): `promote-docs`, `docs-validate`, `docs-naming` 등. 5단 파이프라인 운영용.
- **사용자 배포본** (`content/harness/plugins/*/skills/*`): `harness` (onboarding), `/medi:new`, `/medi:version-cut` 등. 6 role 사용자가 호출.

각 팀이 제각각 SKILL.md 를 작성하면 보안·일관성이 무너진다 (idea-04 동기). 어떤 도구를 호출하는지, 어떤 외부 명령을 실행하는지, 어떤 파일·환경변수를 읽는지가 묵시적이면 감사·리뷰가 불가능. 디렉토리 구조도 제각각이면 *어디에 무엇을 두는지* 가 매번 재학습 부담.

이 ADR 은 두 영역의 **작성 형식·검증 룰을 동일** 하게 두고 **권한 강도만 차등** 한다 (메인테이너는 신뢰 기반, 사용자 배포본은 엄격). [[adr-0001-directory-structure]] 의 디렉토리 위치 결정과 [[adr-0004-frontmatter-naming]] 의 frontmatter 어휘 위에 동작.

## Decision

### 1. SKILL 디렉토리 구조 (표준)

```
<plugin-or-claude>/skills/<skill-name>/
├── SKILL.md              # 필수 — 진입점 (trigger·핵심 흐름·인자), 본문 500자 가이드
├── rules.md              # 필수 — 스킬이 강제하는 룰셋·정책·금지 사항
├── examples/             # 필수 — 사용 예 1+ 자산 (실제 결과물 sample)
├── checklist.md          # 필수 — 운영 체크리스트 (단계별 점검)
├── scripts/              # 선택 — 자동화 명령 (.sh 파일)
└── reference/            # 선택 — rules.md 도 길어지면 분리할 긴 reference
```

| 파일/디렉토리 | 필수 | 책임 |
|---------------|------|------|
| `SKILL.md` | **필수** | 진입점 — *무엇 / 언제 부르나 / 어떻게 호출* (사용자 시점). 500자 가이드 (S3) |
| `rules.md` | **필수** | 스킬이 *강제하는 룰셋·정책·금지 사항* (결과물 시점). § 절들로 구성 |
| `examples/*` | **필수** | 사용 예 1+ 자산 (sample 결과물·scaffold 템플릿) |
| `checklist.md` | **필수** | 운영 체크리스트 (검증 단계·머지 전 점검) |
| `scripts/*.sh` | 선택 | 자동화 명령. `source ../scripts/sanitize.sh` 헬퍼 사용 권장 |
| `reference/*.md` | 선택 | `rules.md` 도 길어지면 분리할 긴 reference |

**SKILL.md vs rules.md 구분 기준** — SKILL.md = "*무엇 / 언제 / 어떻게 호출*" (사용자 시점, 진입점). rules.md = "*무엇을 강제 / 왜 / 위반 시*" (결과물 시점, 룰셋). SKILL.md 가 비대해진 경우 rules 부분을 rules.md 로 분리해야 표준 충족. Claude 는 trigger 시 SKILL.md 만 로드 → 실제 룰 적용 시점에 rules.md 지연 로드 (token 효율).

### 2. SKILL.md frontmatter 스키마

기존 Claude Code subagent 의 `name`/`description`/`tools` 패턴 + 사내 확장 5 필드.

```yaml
---
name: <skill-slug>                      # 필수. kebab-case
description: <스킬 한 줄 설명>           # 필수. 호출 트리거
allowed_tools: [Read, Edit, Bash]       # 필수. 호출 가능 도구 목록
allow_commands: [git push, rm -rf]      # 위험 명령 사용 시 필수
reads_files:                            # 선택 (권장)
  - "[[docs/_map.md]]"
runs_scripts:                           # 선택 (권장)
  - "[[scripts/validate.py]]"
env_vars:                               # 선택 (권장)
  - HARNESS_ROOT
---
```

[[adr-0004-frontmatter-naming]] 의 R4-R9 룰 위에 SKILL.md 전용 룰셋 추가:

| 룰 | 검증 대상 | 위반 시 |
|----|-----------|---------|
| **S1** `allowed_tools` 필수 | 모든 SKILL.md frontmatter | **차단** |
| **S2** `allow_commands` 위험 명령 한정 | 위험 분류 명령 호출 시 frontmatter 에 선언 | **차단** (화이트리스트 외 명령) |
| **S3** 본문 500자 가이드 | frontmatter 제외, unicode codepoint, 코드블록 포함 | **soft 경고** (차단 X) |
| **S4** context 필드 (`reads_files`/`runs_scripts`/`env_vars`) | 미선언 시 | **권장** (운영 후 강제 전환 검토) |
| **S5** `examples/` + 1+ 자산 | SKILL 디렉토리 | **차단** |
| **S6** `checklist.md` 존재 | SKILL 디렉토리 | **차단** |
| **S7** `rules.md` 존재 | SKILL 디렉토리 | **차단** |
| **S8** 동적매핑 sanitize | `scripts/*.sh` 가 동적 입력 (`$VAR`·CLI 인자·파일 경로) 사용 시 `source sanitize.sh` 또는 인용 규칙 (`"$VAR"`·`printf %q`) | **soft 경고** (정적 분석 한계) |

### 3. 위험 명령 분류 (`allow_commands`)

기준: **현재 셸 환경 외부에 영향 + 되돌리기 어려움**.

| 카테고리 | 예시 | 분류 |
|----------|------|------|
| 파일 시스템 destructive | `rm`, `mv`, `chmod`, `chown` | **위험 — 화이트리스트 필수** |
| 네트워크 호출 | `curl`, `wget`, `nc`, `ssh` | **위험** |
| VCS write | `git push`, `git tag`, `git reset --hard`, `git commit` | **위험** |
| 패키지 install | `npm install`, `pip install`, `brew install` | **위험** |
| 시스템 권한 | `sudo`, `su` | **위험** |
| read-only | `ls`, `cat`, `echo`, `grep`, `find`, `git status`, `git log`, `git diff` | **안전 — 선언 불필요** |

영역별 차등:
- **메인테이너용**: 위험 명령 자유 선언 (예: `promote-docs` 의 `git tag`).
- **사용자 배포본**: 위험 명령 최소화. 사용자 환경 손상 위험 — *꼭 필요한 명령만* 선언, 본문에 사용 이유 명시.

### 4. SKILL.md 본문 스켈레톤

```markdown
# <Skill Title>

<스킬이 하는 일 1~2문장. 500자 이내>

## When to use
<호출 트리거 — 어떤 상황에서 부르는가>

## What it does
<핵심 동작 1-3 단계>

## 보안 고려사항
- `allow_commands` 선언 이유: ...
- 접근 금지 경로·동작: `.env`, `secrets/` 읽기 금지 등
- 동적 입력: `scripts/sanitize.sh` 사용 또는 직접 인용 규칙 준수
```

본문 500자 초과 시 `reference/` 또는 `examples/` 로 분리.

### 5. `scripts/sanitize.sh` 공용 헬퍼

`.claude/skills/scripts/sanitize.sh` 단일 파일 안 함수 라이브러리. 스킬이 `source` 후 함수 호출.

| 함수 | 책임 |
|------|------|
| `sanitize_slug <input>` | kebab-case 슬러그화 |
| `validate_kebab_case <input>` | 패턴 (`^[a-z0-9]+(-[a-z0-9]+)*$`) 검증 |
| `quote_arg <input>` | 셸 인용 (`printf '%q'`) — 인젝션 방지 |
| `validate_path <input>` | 경로 탈출 (`../`) / 절대경로 / 심볼릭 검증 |

사용 강제 X — 본문 가이드에서 권장만. 동적 입력을 직접 셸/경로/프롬프트에 삽입 시 sanitize 함수 통과 권장.

### 6. 검증 도구

기존 `docs-validate` 를 multi-target 으로 확장 — `docs/idea` + `docs/spec` + `docs/adr` + `.claude/skills/*/SKILL.md` + `content/harness/plugins/*/skills/*/SKILL.md` 동시에. SKILL.md 전용 룰셋 (S1-S4) 을 별도 모듈로 추가, 도구 진입점은 단일 (`docs-validate`) 유지.

## Alternatives Considered

| 후보 | 채택 안 한 이유 |
|------|------------------|
| 디렉토리 구조 자유 | 매 스킬마다 재학습 부담. 일관성 ↓ |
| `tools/` + `templates/` + `docs/` 등 다른 명명 | 기존 메인테이너 스킬 3개가 이미 `scripts/` + `examples/` 패턴 따름. 일관성 깨질 이유 없음 |
| frontmatter 필드 더 많이 (예: `cost_estimate`, `expected_runtime`) | YAGNI. 현재 결정된 5 필드로 시작, 운영 후 추가 |
| `sanitize` 를 함수 라이브러리 X 단일 스크립트만 | 함수 분리가 호출 단순. 라이브러리 채택 |
| 메타 docs frontmatter 와 통합 (1 ADR) | 검증 대상이 다름 (메타 docs vs SKILL.md). 별도 ADR ([[adr-0004-frontmatter-naming]] 와 분리) 가 정확 |
| 별도 검증 도구 신설 | `docs-validate` 와 중복. multi-target 확장이 단순 |

## Implementation Path

| Action | 누가 | 언제 | 의존 / 산출 |
|--------|------|------|--------------|
| 기존 SKILL.md 3개 (`docs-naming`/`docs-validate`/`promote-docs`) frontmatter retrofit (S1-S4 룰 적용) | 메인테이너 | v0.1 release 전 | 기존 스킬 유지 + 필드 추가 |
| `.claude/skills/scripts/sanitize.sh` 헬퍼 라이브러리 작성 (4 함수) | 메인테이너 도구 | v0.1 release 전 | 공용 헬퍼 |
| `docs-validate` multi-target 확장 (S1-S4 룰셋 추가) | 메인테이너 도구 | v0.1 release 전 | [[adr-0005-version-rollout]] V1 CI 의 일부 |
| `create-skill.sh` 스크립트 (skill scaffold 자동 생성: SKILL.md + scripts/ + examples/) | 메인테이너 도구 | 신규 SKILL 빈도 ↑ 시 follow-up | `promote-docs/scripts/` 의 일부 |
| 사용자 배포본 SKILL.md 작성 시 위 룰 + 디렉토리 구조 적용 | 메인테이너 | v0.1+ release | base + role plugin 의 skills/ |

**시나리오 예 (메인테이너가 새 SKILL 작성)**

1. `bash create-skill.sh <skill-name>` (follow-up 이후) → `<location>/skills/<skill-name>/SKILL.md` + `scripts/` + `examples/` scaffold.
2. 메인테이너가 `SKILL.md` frontmatter 채움 (`allowed_tools`, `allow_commands`, ...).
3. 본문 500자 이내 작성 (When to use / What it does / 보안).
4. PostToolUse 훅 → `docs-validate` 가 S1-S4 + R4-R9 검증.
5. 통과 시 머지 가능, 실패 시 차단 메시지.

## Consequences

**Pros**
- 두 영역 (메인테이너 + 사용자 배포본) 같은 작성 형식 — 학습 비용 ↓.
- 디렉토리 구조 표준화 — 매 스킬마다 *어디에 무엇* 재학습 부담 ↓.
- frontmatter 의 `allowed_tools`/`allow_commands` 가 도구·명령 접근을 명시적으로 표면화 → 감사·리뷰 가능.
- 기존 SKILL.md 3개가 이미 같은 디렉토리 패턴 — retrofit 부담 작음.
- 사용자 배포본의 위험 명령 엄격 분류 → 사용자 환경 손상 방지.

**Cons**
- 기존 SKILL.md 3개 retrofit 작업 부담 (frontmatter 누락 필드 추가).
- `create-skill.sh` 같은 보조 도구 없으면 신규 SKILL 작성 시 frontmatter scaffold 수동 — 실수 위험.
- 위험 명령 분류 기준이 *카테고리만* 명시 — 새 명령 (예: `kubectl apply`) 등장 시 분류 모호.
- `docs-validate` 가 SKILL.md 도 검증 → 첫 운영 시 성능 영향 미측정.

**Follow-ups**
- [ ] `reads_files`/`runs_scripts`/`env_vars` 권장 → 강제 전환 시점 (운영 6개월 후 위반 사례 측정).
- [ ] `validate.py` SKILL.md 추가 시 성능 영향 측정.
- [ ] `validate.py` R11 박기 — S5/S6/S7 디렉토리 존재 검증 (`.claude/skills/*/`, `content/harness/plugins/*/skills/*/`, `content/harness/plugins/*/skills/<role>/*/`).
- [ ] `create-skill.sh` 도입 — S5–S7 강제 결정으로 우선순위 ↑. 신규 SKILL scaffold 가 4 필수 자산 (SKILL.md + rules.md + examples/sample.md + checklist.md) 자동 박음.
- [ ] 기존 3 SKILL 마이그레이션 — SKILL.md 의 룰셋 부분을 rules.md 로 분리. `docs-naming/checklist.md` 신규 박기.
- [ ] 새 위험 명령 카테고리 등장 시 분류 기준 갱신.

## Notes

- 2026-04-29: status proposed → accepted. source [[spec-13-skill-authoring-rules]] status → accepted (통째 흡수).
- 2026-04-30: §1 표 갱신 — `rules.md` (신규) / `examples/` / `checklist.md` *선택* → **필수** 승격. SKILL.md vs rules.md 책임 분리 (사용자 시점 진입점 vs 결과물 시점 룰셋). Claude trigger 시 SKILL.md 만 로드 → 실제 룰 적용 시점에 rules.md 지연 로드 (token 효율). S5–S8 룰 추가 — examples/checklist/rules 디렉토리 존재 차단 + sanitize soft 경고. 운영 사실 표준 (메인테이너 스킬 3개 examples 3/3, scripts 3/3 보유) 박제 + `rules.md` 로 SKILL.md 비대 root cause 해소. 마이그레이션 영향 — 기존 3 SKILL (`docs-naming` / `docs-validate` / `promote-docs`) 의 SKILL.md 본문 룰셋 → rules.md 이전. validate.py R11 (S5/S6/S7 디렉토리 존재) follow-up.
