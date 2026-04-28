---
id: idea-04
type: idea
status: absorbed
created: 2026-04-28
tags: [idea]
---

# skill authoring rules

플러그인에 스킬 만들 때 따라야 할 원칙(컨벤션)이 필요하다.

## 핵심 제약

- **본문 길이 상한**: SKILL.md 본문은 500자 이내. 길면 `scripts/`, `examples/`, 별도 reference 문서로 분리.
- **tools / context 설정 규칙**: 어떤 스킬이 어떤 tool 을 호출할 수 있는지, 어떤 컨텍스트(파일 경로, 환경변수)를 읽는지 명시적으로 선언하는 규약이 필요.
- **보안 규칙**: 스킬이 접근할 수 있는 경로/네트워크/시크릿 범위를 선언. 외부 명령(`rm`, `curl`, `git push` 등) 화이트리스트, 금지 동작(`.env`/`secrets/` 읽기, 임의 URL fetch 등) 명시.
- **동적 입력 처리**: 사용자 인자·외부 응답을 그대로 셸/경로/프롬프트에 끼워넣지 않는다. 인자 검증(허용 문자, 길이, 슬러그화)과 인용 규칙, 셸 인젝션·경로 탈출 방지 패턴을 정해둔다.

## 결정

| # | 항목 | 결론 | 강제 수준 |
|---|------|------|-----------|
| 1 | 본문 길이 측정 | 500자 내외 (frontmatter 제외, unicode codepoint, 코드블록 포함). `validate.py` 의 long-body 패턴 재사용 | **soft 경고** (차단 X) |
| 2 | tools 화이트리스트 | frontmatter 필수 필드 `allowed_tools: [Read, Edit, Bash, ...]` + 본문 1줄 설명. Claude Code subagent 의 `tools` 패턴 재사용 | **차단** (필드 누락 시) |
| 3 | context 구조화 | frontmatter 선택 필드 3개: `reads_files` / `runs_scripts` / `env_vars` (위키링크·리스트) | 권장. 운영 후 강제 전환 검토 |
| 4 | 보안 정책 | 본문 가이드 (모든 스킬 공통) + 위험 동작 한정 frontmatter `allow_commands: [git push, rm, ...]` 화이트리스트. 미선언 = 안전 명령만 허용 | **차단** (화이트리스트 외 명령 호출 시) |
| 5 | 동적 입력 검증 | 공용 헬퍼 `scripts/sanitize.sh` (또는 함수 라이브러리) 제공 + 본문 가이드에서 동적 입력 직접 셸 삽입 금지 명시 | 헬퍼 사용 강제 X. 위반은 코드 리뷰 |
| 6 | 위반 검증 도구 | `docs-validate` 일반화. 기존 idea/spec/adr 검증 + SKILL.md 룰셋 추가 (별도 도구 X). 룰셋은 #2-5 결정에서 자동 도출 | #2 차단 / #3 권장 / #4 차단 / #5 가이드 |

핵심 발상:
- **frontmatter = 강제 가능한 메타** (`allowed_tools`, `allow_commands`)
- **본문 가이드 = 강제 어려운 원칙** (보안 의식, 동적 입력 sanitize)
- **공용 헬퍼 = 반복 패턴 줄이는 선택적 도구**

## 참고

- 기존 `.claude/skills/docs-naming/SKILL.md`, `promote-docs/SKILL.md` 가 이미 어느 정도 컨벤션을 따르고 있으니 거기서 추출 가능.
- 검증 도구는 `[[idea-03-user-docs-scaffold]]` 의 `docs-validate` 일반화 결정 (Q4) 의 연장 — 한 도구가 multi-target (idea/spec/adr/SKILL.md) 처리.

## spec 단계로 분기

idea 결정 종료. 분기는 단일 spec 권장:

- **`skill-authoring-rules`** — 결정 6개 모두 한 spec (frontmatter 스키마 + 보안 정책 + 본문 규칙 + 검증 룰셋). 토픽 응집도 높음.

(대안: `skill-frontmatter-schema` / `skill-security-policy` / `skill-body-rules` 3 분할도 가능하지만, `allow_commands` 같은 필드가 보안 ↔ frontmatter 양쪽이라 인위적 분리됨. 1 spec 권장.)
