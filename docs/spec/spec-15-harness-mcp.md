---
id: spec-15
title: Harness MCP
type: spec
status: accepted
created: 2026-04-29
updated: 2026-04-29
sources:
  - "[[idea-06-harness-mcp]]"
owns: harness-mcp
tags: [spec]
aliases: []
related_to:
  - "[[spec-14-harness-hooks]]"
  - "[[spec-11-medi-docs-frontmatter]]"
  - "[[adr-0008-medi-docs-scaffold]]"
  - "[[adr-0010-harness-mcp]]"
depends_on:
  - "[[spec-06-base-hoisting]]"
---

# Harness MCP

## Scope

harness plugin 이 사용자 환경에 자동 등록하는 MCP 서버 셋 — v0.1 = 외부 공식 MCP (GitHub, Atlassian) 번들. plugin manifest 의 `mcpServers` 자동 등록 + 인증 흐름 + 사용자 disable. 자체 medi_docs MCP (lookup·lineage·schema) 는 v0.2+ 로 deferred.

## Summary

medisolve 작업 흐름이 **GitHub** (코드 + medi_docs 저장) + **Atlassian** (Jira 티켓·Confluence 위키) 에 걸쳐있어 v0.1 가치는 두 외부 도구를 LLM 에 통합하는 것. harness plugin 이 두 공식 MCP 서버를 manifest 로 자동 등록하여 사용자는 plugin install 만으로 통합 완료. 자체 medi_docs MCP (idea-06 의 T1~T5) 는 medi_docs 누적량이 충분히 쌓인 후 (M2+) 도입.

## Background

(원본: [[idea-06-harness-mcp]])

원안은 medi_docs 자체 MCP 서버 (T1 lookup, T2 lineage, T3 schema, T4 status, T5 version-diff) 를 v0.1 에 도입하는 것이었다. 그러나 v0.1 시점에서:

1. medi_docs 자체가 새로 scaffold 되는 자산이라 *누적량이 0* — lookup·lineage 가치가 작음.
2. medisolve 의 *기존 데이터* 가 이미 GitHub (repo, issues, PR) + Atlassian (Jira, Confluence) 에 풍부 — 외부 통합이 즉시 가치.
3. 외부 공식 MCP 서버 (GitHub MCP, Atlassian MCP) 가 이미 존재 → 자체 구현 비용 X, 번들만.

따라서 v0.1 = 외부 번들, 자체 medi_docs MCP = M2+ deferred.

## Goals

- v0.1: GitHub MCP + Atlassian MCP 를 plugin manifest 의 `mcpServers` 로 자동 등록.
- 사용자 인증 흐름 (token 입력) 명시 — plugin install 후 첫 사용 직전.
- 사용자 disable 인터페이스 — plugin 단위 (Claude Code native) + 개별 MCP (manifest condition + env var).
- `${CLAUDE_PLUGIN_ROOT}` 변수 기반 plugin 자산 경로 사용.
- 자체 medi_docs MCP = M2+ deferred (idea-06 원안 보존).

## Non-goals

- 자체 medi_docs MCP 서버 구현 (T1~T5) — M2+ 후속 spec 으로 분기.
- GitHub/Atlassian MCP 서버 자체 구현 — harness 는 등록·인증·disable 만, 서버 코드는 외부 공식 그대로.
- harness 메타 docs (harness repo `docs/`) MCP 노출 — 메인테이너 자산.
- hook 자산 → [[spec-14-harness-hooks]].
- skill 자산 → [[spec-12-medi-docs-tooling]].

## Design

### v0.1 MCP 서버 셋 (D1)

| 서버 | 용도 | 출처 | 배포 | 인증 | v0.1 |
|------|------|------|------|------|------|
| **GitHub MCP** | repo·이슈·PR·Actions·코드보안 (80+ tools) | [github/github-mcp-server](https://github.com/github/github-mcp-server) (GitHub 공식) | Docker `ghcr.io/github/github-mcp-server` 또는 Go binary | `GITHUB_PERSONAL_ACCESS_TOKEN` env | **필수** |
| **Atlassian MCP** | Jira·Confluence·Compass | [atlassian/atlassian-mcp-server](https://github.com/atlassian/atlassian-mcp-server) (Atlassian 공식, 클라우드 호스팅 `mcp.atlassian.com/v1/mcp`) | remote HTTP (no local install) | OAuth 2.1 3-legged (권장) 또는 API Token | **필수** |
| (medi_docs MCP) | medi_docs lookup·lineage·schema | 자체 ([[idea-06-harness-mcp]] 원안 T1~T5) | — | — | **deferred (M2+)** |

**deprecated 주의**: 이전 `@modelcontextprotocol/server-github` (npm) 는 2025-05-29 archived. 사용 금지.

**대안**: Atlassian self-hosted 환경이면 [sooperset/mcp-atlassian](https://github.com/sooperset/mcp-atlassian) (PyPI) 가 검증된 third-party. medisolve 가 Atlassian Cloud 전제이면 공식 remote 가 자연스러움.

### 등록 흐름 (D2) — GitHub vs Atlassian 분리

조사 결과 (2026-04-29): Claude Code plugin manifest 의 `mcpServers` 는 **local stdio 서버 자동 등록 ✓** 확인. Remote HTTP MCP (Atlassian 같은 클라우드 호스팅) 의 plugin.json 직접 박기는 **공식 문서 미확인** — 그래서 두 서버 등록 흐름이 다름.

**GitHub (local Docker stdio)** — plugin manifest 자동:

```json
{
  "mcpServers": {
    "harness-github": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-e", "GITHUB_PERSONAL_ACCESS_TOKEN",
        "ghcr.io/github/github-mcp-server"
      ],
      "env": { "GITHUB_PERSONAL_ACCESS_TOKEN": "${HARNESS_GITHUB_TOKEN}" }
    }
  }
}
```

`SessionStart` 시 자동 시작, plugin uninstall 자동 제거.

**Atlassian (remote HTTP + OAuth)** — `harness:setup` skill 이 안내·실행:

```bash
claude mcp add --transport http harness-atlassian https://mcp.atlassian.com/v1/mcp
```

위 명령을 plugin 자체 skill (`/harness:setup atlassian`) 이 1회 자동 호출. 등록 후 사용자가 첫 `/mcp` 호출 시 OAuth 2.1 3-legged 흐름 자동 트리거 (브라우저 동의). 자동 등록 X — *명시적 1회 명령* 패턴.

**자동화 단계**:

| 단계 | 트리거 | 채택 |
|------|--------|------|
| **v0.1** 사용자 명시 호출 (`/harness:setup atlassian`) | 사용자 1회 명령 | **필수** — 단순·명시적 |
| v0.2+ `SessionStart` hook lazy init | 첫 세션에서 setup 미완 감지 시 자동 실행 | 검토 (멱등성 구현·검증 후) |

(plugin postinstall / onInstall 필드 = Claude Code 공식 미지원 확정. SessionStart 우회는 가능하나 표준 패턴 미문서화 → v0.2 검토.)

**대안 검토**:
- `.mcp.json` 을 plugin 이 사용자 repo 안에 박기 — 사용자 자산 침범 X 권장.
- harness 가 자체 proxy 서버 띄워 stdio 변환 — 복잡도 ↑, 채택 X.

### 인증 흐름 (D3)

GitHub 와 Atlassian 의 인증 모델이 다름 — 분리 처리.

| 서버 | 인증 방식 | 입력 시점 | 저장 (사용자 로컬) |
|------|----------|-----------|---------------------|
| GitHub | Personal Access Token (PAT) | 사용자 본인이 shell rc 또는 OS keychain 에 `HARNESS_GITHUB_TOKEN` env 설정 1회 | 사용자 환경 (shell rc / keychain). harness 는 `env` 로 읽기만. |
| Atlassian | OAuth 2.1 3-legged (권장) | `/harness:setup atlassian` 이 `claude mcp add` 1회 호출 → 사용자 첫 `/mcp` 호출 시 브라우저 동의 자동 트리거 | Claude Code 자체 저장 영역 (이미 사용자 로컬). harness 가 별도 보관 X |
| Atlassian (대안) | API Token (조직 관리자가 활성화 시) | 사용자가 `claude mcp add ... --header "Authorization: Bearer <token>"` 1회 호출 | Claude Code mcp config (사용자 로컬) |

**원칙**: token 은 *사용자 각자 로컬 환경* 에 보관. harness plugin 은 token 을 직접 저장·관리 X — 사용자 환경 변수·OS keychain·Claude Code 자체 저장을 *읽기만*. 이유:
- 보안 책임을 plugin 이 떠맡지 않음 (평문 저장·암호화 키 관리 부담 X).
- 사용자 별 token 분산 — 한 plugin 데이터 영역에 모든 사용자 token 모이지 않음.
- 표준 OS·셸 인증 흐름 그대로 활용.

미설정 시 MCP 시작 X — `/harness:setup` 또는 안내 메시지로 *사용자 본인이 env 설정* 안내.

### 사용자 disable (D4)

[[spec-14-harness-hooks]] D3 와 평행:

| 입도 | 메커니즘 | 명령 |
|------|----------|------|
| **plugin 전체** | Claude Code native | `/plugin disable harness` |
| **개별 MCP** | manifest condition + env var | `mcpServers[name].condition: "${HARNESS_MCP_<NAME>_ENABLED:-true}"` |

추가 슬래시 `/harness:mcp list` 는 plugin 자체 skill 로 제공.

### medi_docs MCP deferral (D5)

idea-06 원안의 T1~T5 (medi_docs lookup, lineage, schema, status, version-diff) 는 *medi_docs 누적이 의미 있는 시점* 까지 deferred. 도입 트리거 (M2+ 결정):

- medi_docs 가 N 개 이상 문서 누적 (정확한 임계값 운영 후 결정).
- LLM 이 medi_docs 전체 컨텍스트 로드 시 토큰 비용이 측정 가능한 부담이 됨.
- 사용자 또는 LLM 이 lookup 패턴 반복 호출 — 자동화 가치 명시.

## Interface

### plugin manifest mcpServers 어휘 (Claude Code 공식)

`command`, `args`, `env` + `${CLAUDE_PLUGIN_ROOT}` `${CLAUDE_PLUGIN_DATA}` `${ENV_VAR}` 변수 사용 가능.

### 슬래시 커맨드 (harness plugin 자체 제공)

- `/harness:auth github <token>` — GitHub token 저장.
- `/harness:auth atlassian <host> <token>` — Atlassian 인증 저장.
- `/harness:mcp list` — 등록된 harness MCP + 인증·활성 상태.

plugin 단위 on/off 는 Claude Code native `/plugin enable|disable harness` 그대로 사용.

## Alternatives Considered

- **v0.1 = 자체 medi_docs MCP** (idea-06 원안) — medi_docs 누적량 0 시점에 lookup 가치 작음. 외부 통합 우선이 ROI ↑. 채택 X.
- **GitHub/Atlassian 서버 자체 구현** — 공식 서버 존재 → 재발명 비용. 채택 X.
- **사용자 수동 `claude mcp add`** — plugin 가치 ↓ + 학습 비용 ↑. plugin manifest 자동 등록이 자연스러움.
- **token 을 plugin manifest 에 평문 박기** — 보안 위반. env var + skill 인증 흐름이 표준.

## Open Questions

- [x] (D1.a) GitHub 공식 MCP 서버 — **확인 (2026-04-29)**: `github/github-mcp-server` (GitHub 자체 관리). 배포 = Docker `ghcr.io/github/github-mcp-server` 또는 Go binary. 인증 = `GITHUB_PERSONAL_ACCESS_TOKEN`. 이전 `@modelcontextprotocol/server-github` (npm) 는 2025-05-29 archived 사용 금지.
- [x] (D1.b) Atlassian MCP 서버 — **확인 (2026-04-29)**: `atlassian/atlassian-mcp-server` (Atlassian 공식, 클라우드 호스팅 `mcp.atlassian.com/v1/mcp`). 인증 OAuth 2.1 3-legged 권장 또는 API Token. self-hosted 환경이면 [sooperset/mcp-atlassian](https://github.com/sooperset/mcp-atlassian) (PyPI) 검증된 third-party. medisolve Cloud 전제이면 공식 remote 채택.
- [x] (D2.e) Claude Code plugin manifest mcpServers 의 remote HTTP transport 지원 — **확인 (2026-04-29)**: `.mcp.json` 또는 `claude mcp add --transport http` CLI 는 remote HTTP 정식 지원. plugin.json 의 mcpServers 안에 직접 박는 패턴은 **공식 문서 미확인** → Atlassian 은 plugin manifest 자동 등록 X, `harness:setup` skill 이 `claude mcp add` 호출 패턴 채택. 출처: code.claude.com/docs/en/mcp.
- [x] (D2.f) plugin postinstall hook 자동 호출 — **확인 (2026-04-29)**: Claude Code plugin manifest 에 `onInstall`/`postInstall` 필드 **없음**. SessionStart hook 으로 *최초 1회만 실행* 패턴은 가능하나 공식 권장 패턴 미문서화. v0.1 = 사용자 명시 호출 (`/harness:setup`), v0.2+ = SessionStart lazy init 검토. 출처: code.claude.com/docs/en/plugins-reference.md.
- [x] (D3.c) token 저장 위치 — **결정 (2026-04-29)**: 사용자 각자 로컬 환경 (shell rc / OS keychain / Claude Code 자체 저장) 에 보관. harness plugin 은 token 저장·관리 책임 X, 읽기만. 이유: 보안 책임 회피, 사용자별 분산, 표준 흐름 활용.
- [ ] (D5.d) 자체 medi_docs MCP 도입 트리거 — 정량적 임계값 (문서 N 개) vs 정성적 (사용자 요청). 운영 후 결정.

## Notes

- 2026-04-29: 초기 spec 작성. v0.1 방향 = 외부 GitHub + Atlassian 번들 (사용자 결정). idea-06 원안 자체 MCP 는 D5 에 deferred 명시.
- 2026-04-29: D1.a / D1.b 외부 조사 완료. GitHub = `github/github-mcp-server` (Docker), Atlassian = `atlassian/atlassian-mcp-server` (remote HTTP + OAuth). manifest 예시·인증 흐름 갱신. 새 OQ D2.e (remote transport 지원) 추가.
- 2026-04-29: D2.e 외부 조사 완료. plugin.json mcpServers 에 remote HTTP 직접 박기 미확인 → Atlassian 은 `harness:setup` skill 이 `claude mcp add` 호출 패턴 채택. 새 OQ D2.f (postinstall hook 자동 트리거) 추가.
- 2026-04-29: D3.c 결정. token 은 사용자 각자 로컬 보관, harness 는 읽기만. plugin 보안 책임 회피.
