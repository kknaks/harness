---
name: harness
description: mediness 단일 plugin 의 사용자 진입점. /harness init <role> 로 role-templates 의 SKILL 들을 현재 프로젝트의 .claude/ 로 복사 (scaffolder 모델). 처음 셋업 / role 추가 / 갱신 / 상태 확인 / 정리 통합. 단일 명령 — sub-command 는 첫 인자.
allowed_tools: [Read, Edit, Bash]
allow_commands:
  - "claude plugin list"
reads_files:
  - "[[role-templates/README.md]]"
  - "[[~/.claude/settings.json]]"
runs_scripts:
  - "[[scripts/init.sh]]"
  - "[[../../scripts/scaffold-medi-docs.sh]]"
env_vars:
  - HARNESS_GITHUB_TOKEN
  - HARNESS_MCP_GITHUB_ENABLED
---

# Harness — Mediness Onboarding

mediness `harness` plugin 의 **사용자 진입점**. plugin 자체는 *전역* 에 한 번 install (`/plugin install harness`). 본 SKILL 이 *프로젝트별 scaffolder* 역할 — `/harness init <role>` 호출 시 plugin 의 `role-templates/<role>/` 를 현재 프로젝트의 `.claude/` 로 복사. 사용자가 SKILL 본문을 git commit 으로 팀과 공유 + 프로젝트 단위 커스터마이즈 가능 ([[adr-0014-single-plugin-scaffolder]]).

## When to use

- **처음 셋업** — 새 프로젝트에 mediness 자산 박기 (`/harness init backend` 등)
- **role 추가** — 같은 프로젝트에 다른 role SKILL 추가 (예: backend 위에 qa)
- **갱신** — 메인테이너가 SKILL 갱신 → `/harness init <role> --force` 로 재복사
- **상태 확인** — 현재 프로젝트의 `.claude/` 내용 + plugin install 상태
- **정리** — 프로젝트별 `.claude/skills/<n>/` 삭제 (사용자가 직접 또는 안내)

## How to invoke

```
/harness                       # 상태 확인 (no args)
/harness init <role>           # 단일 role scaffold
/harness init <role> <role>    # 다중 role
/harness init <role> --force   # 기존 파일 덮어쓰기 (갱신 받을 때)
```

사용 가능한 role 목록은 plugin 의 [`role-templates/README.md`](../../role-templates/README.md) 참조. v0.1 = `backend` (`code-review`, `test-design` 2 SKILL). frontend / planner / pm / qa / infra 는 v0.2+ 누적.

## What it does

1. **상태 확인 우선** — `claude plugin list` (plugin install 여부) + `ls .claude/skills/` (프로젝트 자산 목록) 보고
2. **의도 파악** — 사용자 인자 (`init <role>`) 또는 자유 텍스트 → 시나리오 분기
3. **`init` 호출** — `scripts/init.sh <role...> [--force]` 실행:
   - `role-templates/<role>/skills/*` → `<project>/.claude/skills/<n>/` 복사
   - 기존 파일이 있으면 *기본 skip* (사용자 커스텀 보존). `--force` 시에만 덮어쓰기.
   - role-specific hooks 가 있으면 `<project>/.claude/hooks/` 에 추가
   - **medi_docs scaffold** — 처음 셋업 시 9 카테고리 자동 박힘 ([[adr-0008-medi-docs-scaffold]] §4). 이미 있으면 no-op
4. **결과 보고** — 복사된 자산 / skip 된 자산 / 다음 단계 안내

**v0.1 dogfood** — `init` + 상태 확인까지 박힘. `update`·`uninstall` 별도 sub-command 는 v0.2 (현재는 `init --force` 가 update 역할).

## 갱신 (사용자 커스텀 보존)

기본 정책: **사용자가 편집한 `.claude/skills/<n>/` 는 init 이 건드리지 않음** (skip). 메인테이너가 갱신한 SKILL 을 받으려면 `--force` 명시:

```
/harness init backend --force   # 모든 backend SKILL 덮어쓰기
```

사용자가 원하는 § 만 보존하려면: `--force` 전에 `git diff` 로 변경 검토 → 커스텀 §를 별도 `rules-custom.md` 등으로 분리 → `--force` → 분리한 § 다시 박기. 또는 git stash / commit 으로 백업 후 force.

세밀한 sync (보편 슬롯만 갱신, 사용자 § 보존) 가 필요하면 메인테이너의 [[promote-docs/scripts/sync-skill]] 패턴 차용 후속 작업 (v0.2 + ADR-0014 follow-up).

## 보안 고려사항

- `allow_commands`: `claude plugin list` (read-only). 파일 복사·생성은 `init.sh` 내부에서 → 코드 변경 X.
- 동적 입력 (role 이름·--force 플래그) 처리: `printf %q` 또는 quoted expansion (`"$VAR"`). role 이름은 `init.sh` 가 `role-templates/<role>/` 디렉토리 존재 검증으로 화이트리스트.
- 시크릿 차단 + 출력 마스킹 — 아래 패턴은 read 대상에서 제외하고, 출력에 잡히면 `***` 으로 마스킹.

| 카테고리 | 경로/이름 패턴 | 정규식 (예) |
|----------|----------------|-------------|
| dotenv | `.env`, `.env.*` (`.local`, `.production` 등) | `(^|/)\.env(\..+)?$` |
| 시크릿 디렉토리 | `secrets/`, `secret/`, `credentials/` | `(^|/)(secrets?|credentials)/` |
| 토큰 파일 | `*token*`, `*apikey*`, `*api_key*` | `(token|api[_-]?key)` (대소문자 무시) |
| 키 자료 | `*.pem`, `*.key`, `*.p12`, `*.pfx`, `id_rsa*` | `\.(pem|key|p12|pfx)$\|^id_rsa` |
| 인증 헤더값 | `Authorization: Bearer ...`, `x-api-key: ...` | `(Bearer\s+\S+|x-api-key:\s*\S+)` |

- 위 패턴 매치 시: 입력 거부 (read 단계) + 출력 발견 시 `***` 치환. 사용처 환경별 추가 패턴은 본 § 에 보강.

## 보안 고려사항

- `allow_commands` 선언 이유: (위험 명령 호출 시 — 없으면 "X — read/write only")
- 동적 입력 ($VAR / CLI 인자 / 파일 경로) 처리: `source ../scripts/sanitize.sh` 또는 인용 규칙 (`"$VAR"`/`printf %q`).
- 시크릿 차단 + 출력 마스킹 — 아래 패턴은 read 대상에서 제외하고, 출력에 잡히면 `***` 으로 마스킹.

| 카테고리 | 경로/이름 패턴 | 정규식 (예) |
|----------|----------------|-------------|
| dotenv | `.env`, `.env.*` (`.local`, `.production` 등) | `(^|/)\.env(\..+)?$` |
| 시크릿 디렉토리 | `secrets/`, `secret/`, `credentials/` | `(^|/)(secrets?|credentials)/` |
| 토큰 파일 | `*token*`, `*apikey*`, `*api_key*` | `(token|api[_-]?key)` (대소문자 무시) |
| 키 자료 | `*.pem`, `*.key`, `*.p12`, `*.pfx`, `id_rsa*` | `\.(pem|key|p12|pfx)$\|^id_rsa` |
| 인증 헤더값 | `Authorization: Bearer ...`, `x-api-key: ...` | `(Bearer\s+\S+|x-api-key:\s*\S+)` |

- 위 패턴 매치 시: 입력 거부 (read 단계) + 출력 발견 시 `***` 치환. 사용처 환경별 추가 패턴은 본 § 에 보강.
