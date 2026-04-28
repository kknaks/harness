---
id: idea-01
type: idea
status: absorbed
created: 2026-04-27
tags: [idea]
---

# Distribution Strategy

## 요구사항

1. 회사 Claude Code 사내 표준 배포
2. 다양한 스택 (Python, Vite, Next, Postgres 등)
3. 역할별 알맞은 skill set 자동 매핑 — 6 role (planning/pm/frontend/backend/qa/infra)
4. 자동 업데이트
5. OSS 스타일 거버넌스 (여러 기여자 PR → 중앙 관리자가 머지)

## 옵션 검토

### A. 단일 거대 플러그인

- pro: repo 1개, manifest 1개. 가장 단순.
- con: 모두가 모든 skill 다운로드. 역할별 분리 약함.
- con: skillOverrides 로 비활성 가능하지만 listing 오염.

### B. 역할별 N개 플러그인 (분리 repo)

- pro: 깔끔한 격리. 독립 버전.
- con: 거버넌스 산만. cross-cutting 변경이 N회 PR.
- con: 마켓플레이스도 N개 관리.

### C. 모노레포 + 다중 플러그인 마켓플레이스 ← 추천

- 한 repo 가 `.claude-plugin/marketplace.json` + `plugins/<name>/` 여럿 보유
- `@harness/base` (공통, 점진 형성) + 6 role plugin (`planning`/`pm`/`frontend`/`backend`/`qa`/`infra`)
- 사용자: `claude plugin marketplace add github:<org>/harness` → 본인 역할 plugin 만 install
- `autoUpdate: true` 로 자동 갱신
- CI: PR 한 곳, CODEOWNERS 로 영역별 자동 리뷰어

## 왜 C

- 단일 repo = 단일 거버넌스 흐름 (PR/리뷰/CI 통일).
- 다중 plugin = 사용자 컨텍스트/스토리지 부담 최소화 (frontend 가 Python 스킬 안 받음).
- 마켓플레이스가 plugin 별 버전을 따로 추적.
- base ↔ role plugin 분리로 공통 룰 (커밋 컨벤션, 시크릿 훅 등) 이 자연스럽게 한 곳에 모임 (사전 분할 X — `base` 범위 섹션 참고).
- 역할별 skill set 자동 매핑은 별도 프로비저닝 도구가 아니라 `harness` 스킬이 install 시점에 처리 (온보딩 + 운영 섹션 참고).

## 구조 스케치

```
harness/                          # 사내 조직 GitHub (private)
├── .claude-plugin/
│   └── marketplace.json          # 모든 plugin 등록
├── plugins/
│   ├── base/                     # 모든 역할 공통 (CLAUDE.md, 시크릿 훅, 컨벤션 등)
│   ├── planning/                 # 기획
│   ├── pm/                       # PM
│   ├── frontend/                 # 프론트
│   ├── backend/                  # 백엔드
│   ├── qa/                       # QA
│   └── infra/                    # 인프라
├── CODEOWNERS                    # 영역별 자동 리뷰어
├── CONTRIBUTING.md               # PR 룰
└── .github/workflows/            # CI 검증, 자동 릴리즈
```

6 role 은 [[idea-02-mediness-architecture]] 에서 확정. plugin 이름은 lowercase 영문 kebab.

## Role 책임 예시

각 plugin 이 담는 자산의 윤곽 (확정 아님, 운영하며 형성).

| Plugin | 담는 것 (예시) |
|--------|----------------|
| `base` | 회사 CLAUDE.md, 시크릿 차단 훅, 커밋 컨벤션, 메타 도구(idea→spec→adr) |
| `planning` | 기획서 템플릿, RFP 작성, 시장 분석 흐름 |
| `pm` | 일정 추적, 회의록 정리, 진행 상황 보고서 |
| `frontend` | React/Next/Vite 컨벤션, 컴포넌트 패턴, 디자인 토큰 |
| `backend` | API 설계, DB 마이그레이션, Python/PG 패턴 |
| `qa` | 테스트 시나리오 생성, 회귀 체크, 결함 분류 |
| `infra` | 배포·CI/CD, k8s/Terraform, 시크릿 관리 |

원칙: `base` 는 사전 분할 X — 위 base 항목도 처음엔 해당 role 에 두고, 중복 시 승격.

## Roadmap — 단계 release

6 plugin 동시 시작은 무리. dogfood 가능한 순서로 점진:

| 버전 | 포함 | 의도 |
|------|------|------|
| v0.1 | base + backend | 가장 빨리 dogfood (메인테이너가 백엔드 가정) |
| v0.2 | + frontend, + infra | 개발자 그룹 완성 |
| v0.3 | + qa | 품질 흐름 합류 |
| v0.4 | + planning, + pm | 비개발 역할 합류 |

각 버전은 자체로 사용 가능 — 후속 plugin 은 별도 install 로 추가.

## Plugin Manifest 표준 메타데이터

`plugins/<name>/.claude-plugin/plugin.json` 에 최소 다음 필드:

| 필드 | 값 | 비고 |
|------|------|------|
| `name` | `@harness/<role>` 또는 `@harness/base` | scope prefix 통일 |
| `version` | semver | 모노레포 release 시 동기 갱신 |
| `description` | 한 줄 |  |
| `role` | `base` / `planning` / `pm` / `frontend` / `backend` / `qa` / `infra` | mediness 고유 메타 |
| `maintainer` | github 핸들 또는 팀명 | CODEOWNERS 와 정합 |
| `hookPriority` | 숫자 (낮을수록 먼저) | base 작게, role 크게 |

## `base` 범위 — 일단 구현 후 승격

`base` 에 무엇을 둘지 미리 완벽히 분할하지 않는다. 원칙:

1. 처음에는 모든 자산을 해당 role plugin 에 넣고 시작.
2. 운영하면서 **여러 role 이 같은 자산을 복제하기 시작** 하면 → `base` 로 승격.
3. 후보군: 회사 CLAUDE.md, 시크릿 누출 차단 훅, 커밋 컨벤션, 메타 도구(idea→spec→adr) 등.

이 접근의 효과: 추측으로 base 를 부풀리지 않음. 실제 중복이 신호.

## Resolved (이번 정리에서 확정)

- ✅ 사내 조직 GitHub repo 사용 가능
- ✅ 역할 분류: 6 role (planning/pm/frontend/backend/qa/infra) — idea-02 확정
- ✅ `base` 범위: 사전 분할 X, 중복 발생 시 승격
- ✅ 메타 도구의 base 포함 여부: 위 원칙 따름 (실제 중복 시점에 승격)

## 온보딩 + 운영 — Claude plugin 으로 (`harness`)

신입만 아니라 기존 구성원의 운영(역할 변경, 추가 plugin, 동기화)도 같은 스킬로.

**bootstrap (한 번, 수동)**:
1. Claude Code 설치
2. `claude plugin marketplace add github:medisolve/harness`
3. `claude plugin install harness` (또는 base 의 slash command)

**시나리오 — 한 스킬이 다 처리**

| 시나리오 | 동작 |
|---------|------|
| 처음 셋업 (신입 / 기존 첫 도입) | 역할 prompt → base + role plugin install + env 셋업 |
| 역할 변경 (예: 백엔드 → 인프라) | 기존 role uninstall + 새 role install |
| 다중 역할 (풀스택, side project) | 추가 role plugin install |
| 환경 동기화 (정기) | 회사 CLAUDE.md / 공통 settings 갱신 |
| 정리·재설치 | 전체 uninstall + reinstall |
| 상태 확인 | 현재 설치된 plugin · 역할 보고 |

`harness` 한 명령이 진입점. Claude 가 현재 설치 상태 + 사용자 의도 파악 후 적절한 분기. sub-command 분할은 추후 사용 패턴 보고 검토.

(a) curl one-liner 등은 사내 HTTPS 엔드포인트 운영 부담 있어 미채택. plugin 채널 안에서 모든 게 끝나는 게 우선.

## Hook 우선순위 — 계층 정책 (개념)

같은 이벤트에 여러 plugin hook 이 등록될 때의 정렬 룰. 핵심 원칙: **base = 최하위(gate), role = 상위 override**.

**계층**

```
[높음 - 마지막에 결정 / override]
  role plugin
[낮음 - 먼저 실행 / gate keeper]
  base plugin
```

base 가 먼저 (보안·환경 검증 같은 gate), role 이 나중 (스택별 세부 결정으로 override).

**다중 역할 보유 시 role 간 정렬** (풀스택·겸직)

대부분 한 사람에 한 role 만 설치되지만, 겹치면:
- 1순위 개발자 그룹: 인프라 > 백엔드 > 프론트
- 2순위 기획 그룹: 기획자 > pm
- 3순위 qa

**원칙만 잡고 상세는 spec 으로**

- 어떤 hook 종류에 정확히 적용? (PreToolUse / PostToolUse / UserPromptSubmit ...)
- "override" 가 short-circuit 인지 누적인지
- priority 를 manifest 필드로 명시할지 / 컨벤션으로만 둘지

→ 위 결정은 idea-01 → spec 승격 시 다룬다.

## 버전 정책 — 항상 최신

plugin 간 버전 호환성 매트릭스를 운영하지 않는다. 단순 원칙:

- 모든 plugin 은 `autoUpdate: true` — 새 버전 자동 반영.
- 모노레포라 cross-plugin 변경은 한 PR 에 묶임 → 버전 skew 최소.
- breaking change 필요하면 관련 plugin 들을 한 번에 갱신해 release.
- 사용자는 항상 모든 설치 plugin 의 최신 조합을 받음.

트레이드오프: 운영 단순. bad release 시 모두 영향 → 실패·롤백 정책으로 보완.

**실패·롤백 정책**

| 단계 | 조건 |
|------|------|
| 1. CI 통과 | lint / 단위 검증 / manifest 스키마 |
| 2. dogfood tag | 메인테이너 환경에서 24h 운영, 회귀 없음 확인 |
| 3. release tag | 모든 사용자에게 autoUpdate 반영 |
| 4. 문제 발견 | 직전 release tag 로 force update + post-mortem ADR |

## Out of Scope

- **MCP 서버** — 미사용 결정. 사내 MCP 인프라 운영 안 함. 향후 필요 시 별도 idea/spec 으로 분기.
- **public marketplace 배포** — 사내 전용. github private 조직에서 받음.
- **non-Claude 도구 통합** — Cursor, Copilot 등 다른 AI 도구는 본 하네스 범위 외.

## Open Questions

(모두 해소됨 — spec 승격 준비)
