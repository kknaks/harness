---
id: idea-06
type: idea
status: absorbed
created: 2026-04-29
tags: [idea]
---

# Harness MCP

harness plugin 이 노출할 MCP 서버. 사용자 medi_docs (planning/plan/spec/...) 의 진실을 LLM 이 효과적으로 활용하도록 *읽기 인터페이스* 로 제공한다. 현재 harness 에 MCP 서버는 없음 — 신설.

## 핵심 제약

- **읽기 전용 권장**: medi_docs 쓰기는 `/medi:new`, `/medi:version-cut` 같은 skill 책임. MCP 는 lookup·search·schema 노출.
- **자동 등록**: plugin install 시 MCP 서버 등록 (`claude mcp add` 자동 또는 manifest). uninstall 시 제거.
- **사용자 disable**: hook 과 동일하게 끌 수 있어야 함.
- **컨텍스트 효율**: 9 카테고리 전부 LLM 컨텍스트 로드 X. MCP 가 *필요한 부분만* 반환 → 토큰 비용 ↓.
- **권한 범위**: 사용자 repo 의 `medi_docs/` 만 읽기. 다른 경로 접근 X.

## 후보 MCP tool 셋

| # | tool | 입력 | 출력 |
|---|------|------|------|
| T1 | `medi_lookup` | `category, query` | 해당 카테고리에서 query 매칭하는 문서 목록 (제목·요약·경로) |
| T2 | `medi_lineage` | `doc_id` | 그 문서의 sources/related_to/depends_on 그래프 lineage |
| T3 | `medi_schema` | `category` | 카테고리별 frontmatter 필수·선택 필드 (template.md 기반) |
| T4 | `medi_status` | (없음) | `current/` 9 카테고리별 문서 수·status 분포 요약 |
| T5 | `medi_version_diff` | `v_from, v_to` | 두 박제 시점 간 추가/수정/삭제 문서 diff |

## 핵심 발상

- **MCP = medi_docs 의 LLM 어댑터** — frontmatter 그래프·9 카테고리 구조를 LLM 이 *호출 가능한 tool* 로 노출. LLM 이 medi_docs 전체 읽지 않고 필요한 부분만 가져감.
- **읽기 전용 = 쓰기는 skill** 분리 ([[idea-02-mediness-architecture]] 권한 모델 평행). MCP 가 docs 손대지 않음.
- **버전 인식** — T5 같은 도구가 `v{label}/` 박제 시점 활용 → "v1.0 시점에 spec-X 가 어땠는지" 같은 시점 질의 가능.

## Open Questions

- [ ] (a) MCP 서버 런타임 — Python? TypeScript? Claude Code MCP SDK 가 무엇 지원하는지 확인 필요.
- [ ] (b) MCP install 자동화 메커니즘 — plugin manifest 가 MCP 서버 정의 가능? 아니면 install hook 으로 `claude mcp add` 자동 호출?
- [ ] (c) 첫 출시 tool 셋 — T1 + T3 만 시작 (YAGNI: lookup + schema), 또는 T2 까지 (lineage 도 핵심), 또는 다섯 개 다?
- [ ] (d) MCP 호출량 가드 — LLM 이 무한 lookup 하지 않도록 rate limit 또는 결과 cap?
- [ ] (e) 박제 버전 지원 — T1/T2 가 `v{label}/` 도 검색 대상? 아니면 `current/` 만?
- [ ] (f) MCP 서버가 노출하는 인증·권한 — 사용자 repo 안 medi_docs 만 접근하도록 어떻게 제한?

## spec 분기

단일 spec 권장: **`harness-mcp`** — 서버 패키징 + 기본 tool 셋 (T1+T3 우선) + install/disable 동작 + 권한 범위. 토픽 응집도 높음.

대안: tool 셋 따로 spec — T1~T5 가 동일 서버 안 동거하므로 인위적 분리. 1 spec 권장.

## 2026-04-29 업데이트 — v0.1 방향 변경

[[spec-15-harness-mcp]] 작성 중 사용자 결정으로 v0.1 = **외부 GitHub MCP + Atlassian MCP 번들**. 본 idea 의 medi_docs lookup tools (T1~T5) 는 v0.2+ 로 deferred.

이유:
- medi_docs 자체가 새로 scaffold 되는 자산 — v0.1 시점 누적량 0, lookup 가치 작음.
- medisolve 의 *기존 데이터* 가 GitHub + Atlassian 에 풍부 — 외부 통합 ROI ↑.
- 외부 공식 MCP 서버 존재 → 자체 구현 비용 X.

본 idea 의 T1~T5 설계는 [[spec-15-harness-mcp]] §D5 에 deferred 명시 + 도입 트리거 OQ 로 보존.

## 관련

- [[idea-02-mediness-architecture]] — 권한 모델 (사용자 repo 만 접근).
- [[idea-05-harness-hooks]] — plugin 자산 평행 (hooks ↔ MCP). install/disable 동작 공통 패턴.
- [[spec-06-base-hoisting]] — plugin 자산 패키징 위치.
- [[spec-11-medi-docs-frontmatter]] — T3 (`medi_schema`) 가 노출하는 frontmatter 룰.
- [[adr-0008-medi-docs-scaffold]] — `current/` + `v{label}/` 모델 (T5 가 활용).
