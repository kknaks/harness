---
id: adr-0010
title: Harness MCP
type: adr
status: accepted
date: 2026-04-29
sources:
  - "[[spec-15-harness-mcp]]"
tags: [adr]
aliases: []
depends_on:
  - "[[adr-0008-medi-docs-scaffold]]"
  - "[[adr-0011-base-hoisting]]"
related_to:
  - "[[adr-0009-harness-hooks]]"
---

# Harness MCP

## Context

(승격 원본: `docs/spec/spec-15-harness-mcp.md`)

medisolve 작업 흐름 = **GitHub** (코드 + medi_docs 저장) + **Atlassian** (Jira 티켓·Confluence 위키). v0.1 시점에 medi_docs 자체는 [[adr-0008-medi-docs-scaffold]] 직후라 누적량 0 — 자체 MCP lookup 가치가 작음. 반면 외부 GitHub/Atlassian 데이터는 이미 풍부 → 외부 MCP 통합이 즉시 ROI.

[[idea-06-harness-mcp]] 원안은 자체 medi_docs MCP (T1~T5) 였으나 **v0.1 = 외부 번들** 로 우선순위 재정렬. 자체 medi_docs MCP 는 medi_docs 누적이 의미 있는 시점까지 deferred.

## Decision

### 1. v0.1 MCP 서버 셋

| 서버 | 출처 | 배포 | 인증 | v0.1 |
|------|------|------|------|------|
| **GitHub MCP** | [github/github-mcp-server](https://github.com/github/github-mcp-server) (GitHub 공식) | Docker `ghcr.io/github/github-mcp-server` | `GITHUB_PERSONAL_ACCESS_TOKEN` | **필수** |
| **Atlassian MCP** | [atlassian/atlassian-mcp-server](https://github.com/atlassian/atlassian-mcp-server) (Atlassian 공식) | remote HTTP `https://mcp.atlassian.com/v1/mcp` | OAuth 2.1 3-legged (권장) / API Token (대안) | **필수** |
| (medi_docs MCP) | 자체 ([[idea-06-harness-mcp]] T1~T5) | — | — | **deferred (M2+)** |

이전 npm `@modelcontextprotocol/server-github` 는 2025-05-29 archived — 사용 금지.

### 2. 등록 흐름 — transport 별 분리

**Host plugin (v0.1)** = `backend/plugin.json`. [[adr-0005-version-rollout]] v0.1 release scope = `base + backend` 한 쌍이라 v0.1 에 자연 host. 다른 개발 role (frontend / infra / qa) release 시점에 동일 MCP 필요해지면 [[adr-0011-base-hoisting]] §3 hoisting 트리거 발동 (2 곳 이상 복제) → `base/plugin.json` 으로 승격. 사전 분할 X.

**GitHub (local Docker stdio)** — `backend/plugin.json` `mcpServers` 자동 등록:
```json
{
  "mcpServers": {
    "harness-github": {
      "command": "docker",
      "args": ["run", "-i", "--rm", "-e", "GITHUB_PERSONAL_ACCESS_TOKEN", "ghcr.io/github/github-mcp-server"],
      "env": { "GITHUB_PERSONAL_ACCESS_TOKEN": "${HARNESS_GITHUB_TOKEN}" }
    }
  }
}
```
SessionStart 자동 시작, plugin uninstall 자동 제거.

**Atlassian (remote HTTP)** — plugin.json mcpServers 의 remote 직접 박기 = Claude Code 공식 미확인. `/harness:setup atlassian` skill 이 1회 호출:
```bash
claude mcp add --transport http harness-atlassian https://mcp.atlassian.com/v1/mcp
```
첫 `/mcp` 호출 시 OAuth 흐름 자동 트리거 (브라우저 동의). v0.2+ SessionStart lazy init 도입 검토.

### 3. 인증 — token 사용자 로컬 보관

| 서버 | 인증 방식 | 보관 위치 (사용자 로컬) |
|------|-----------|--------------------------|
| GitHub | Personal Access Token | shell rc / OS keychain (env var `HARNESS_GITHUB_TOKEN`). harness 는 읽기만 |
| Atlassian | OAuth 2.1 3-legged | Claude Code 자체 저장 영역 |
| Atlassian (대안) | API Token | `claude mcp add --header "Authorization: Bearer ..."` (Claude Code mcp config) |

harness plugin 은 token 저장·관리 책임 X. 보안 책임 회피 + 사용자별 분산 + 표준 OS·셸 흐름 활용.

### 4. Disable 인터페이스

[[adr-0009-harness-hooks]] §3 평행:

| 입도 | 메커니즘 | 명령 |
|------|----------|------|
| plugin 전체 | Claude Code native | `/plugin disable harness` |
| 개별 MCP | manifest condition + env var | `${HARNESS_MCP_<NAME>_ENABLED:-true}` |

추가 슬래시 `/harness:mcp list` 는 plugin 자체 skill 로 등록·인증·활성 상태 출력.

### 5. 자체 medi_docs MCP deferral

[[idea-06-harness-mcp]] 원안 T1~T5 (lookup·lineage·schema·status·version-diff) = M2+ deferred. 도입 트리거 (운영 후 결정):

- medi_docs N 개 이상 누적 (정량 임계값).
- LLM 의 medi_docs 전체 컨텍스트 로드 토큰 비용이 측정 가능한 부담.
- 사용자/LLM 의 lookup 패턴 반복 호출 — 자동화 가치 명시.

## Alternatives Considered

| 후보 | 채택 안 한 이유 |
|------|------------------|
| v0.1 = 자체 medi_docs MCP (idea-06 원안) | 누적량 0 시점 가치 작음. 외부 통합 ROI ↑ |
| GitHub/Atlassian 자체 구현 | 공식 서버 존재 → 재발명 비용 |
| 사용자 수동 `claude mcp add` (GitHub 도) | plugin 가치 ↓, 학습 비용 ↑. local stdio 자동 등록 가능 |
| token 평문 박기 / plugin data 영역 저장 | 보안 위반. 사용자 로컬 보관이 표준 |
| `.mcp.json` 사용자 repo 안 박기 | 사용자 자산 침범 |
| harness 자체 proxy 서버 (stdio 변환) | 복잡도 ↑ |

## Implementation Path

| Action | 누가 | 언제 | 의존 |
|--------|------|------|------|
| `backend/plugin.json` `mcpServers` 에 GitHub Docker entry | 메인테이너 | v0.1 release 전 | [[adr-0011-base-hoisting]] |
| `/harness:setup atlassian` skill 작성 (`claude mcp add --transport http` 호출) | 메인테이너 | v0.1 | — |
| `/harness:auth github <pat>` skill (env var 안내·검증) | 메인테이너 | v0.1 | — |
| `/harness:mcp list` skill (등록·인증 상태 출력) | 메인테이너 | v0.1 | — |
| Docker 미설치 사용자 안내 메시지 (Go binary 대안) | 메인테이너 | v0.1 | — |
| medi_docs MCP 자체 구현 (deferred) | — | M2+ | 운영 후 트리거 |

## Consequences

**Pros**
- 사용자 plugin install 직후 GitHub MCP 즉시 활성 (Docker stdio 자동 등록).
- Atlassian 도 `/harness:setup atlassian` 1회 명령만으로 통합.
- 외부 공식 서버 사용 → harness 가 서버 코드 유지보수 부담 X.
- token 사용자 로컬 보관 → plugin 보안 책임 회피, 사용자별 분산.
- medi_docs MCP deferred → idea-06 설계 보존, 누적 시점 도입.

**Cons**
- Atlassian 자동 등록 X — 사용자 1회 명령 학습 비용.
- plugin manifest remote HTTP 직접 박기 미확인 → 향후 Claude Code 가 지원하면 등록 흐름 단순화 가능.
- GitHub Docker 의존 — Docker 미설치 사용자에게 Go binary 대안 안내 필요.

**Follow-ups**
- [ ] postinstall hook 자동 호출 / SessionStart lazy init 패턴 v0.2 도입 검토.
- [ ] medi_docs MCP 도입 정량 임계값 결정 (운영 후, spec-15 D5.d 살아있음).
- [ ] Docker 미설치 환경 대응 (Go binary 자동 fallback 가능한가).
- [ ] Atlassian self-hosted 환경 사용자 — `sooperset/mcp-atlassian` 옵션 명시 안내.
- [ ] Claude Code plugin manifest 의 remote MCP 직접 박기 지원 여부 추후 재확인.

## Notes

- 2026-04-29: [[spec-15-harness-mcp]] → ADR 승격. 외부 조사 결과 (GitHub MCP 공식 패키지·Docker 배포, Atlassian remote HTTP + OAuth, plugin manifest remote 미확인, postinstall hook 미지원) 반영 후 박제. spec-15 status accepted 유지.
- 2026-04-29: 정합성 검증 후 §2 에 host plugin = `backend/plugin.json` (v0.1) 명시. [[adr-0011-base-hoisting]] hoisting 모델 적용 — 다른 개발 role 에서 동일 MCP 필요 시 base 로 승격.
