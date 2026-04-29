---
id: spec-04
title: Permissions Flow
type: spec
status: decided
created: 2026-04-28
updated: 2026-04-29
sources:
  - "[[idea-02-mediness-architecture]]"
owns: permissions-flow
tags: [spec]
aliases: []
---

# Permissions Flow

## Scope

단계별 쓰기 권한과 외부 노출 표면(inbox PR 입구, harness plugin 출구). hook 실행 순서는 spec-08 참고.

## Summary

쓰기 권한과 외부 노출 표면을 정의한다. 콘텐츠 5단 중 외부에 보이는 건 **양 끝**(inbox 입구, harness 출구)뿐, 가운데 3단은 메인테이너 내부 작업장.

## Background

inbox 는 공용 raw 집합소지만 무방비여선 안 됨. 가운데 3단은 사용자 입장에서 보이지 않으므로 무거운 권한 메커니즘 불필요. (idea-02)

## Goals

- 단계별 쓰기 권한 명시
- 외부 노출 표면 단순화 (양 끝만)
- inbox 입구 워크플로우 정의 (Git PR)
- 가운데 단계의 운영 자유도 보장

## Non-goals

- 권한 강제 메커니즘(CODEOWNERS / 훅) — 관례 + 메인테이너 자기 규율로 충분
- 비개발 마찰 대응 채널 추가 (운영 후 판단)
- 승격 절차 — `[[spec-05-promote-skills]]`

## Design

**권한 표**

| 레이어 / 단계 | 누가 쓰기 |
|---------------|-----------|
| 메타 (`docs/idea`, `docs/spec`, `docs/adr`) | 메인테이너 |
| 콘텐츠 inbox | **모든 기여자 (공용)** |
| 콘텐츠 sources / wiki / adr / harness | 메인테이너 |

원칙: **inbox 만 공용 입구**, 그 너머는 메인테이너 책임.

**외부 노출 표**

| 단계 | 인터페이스 | 흐름 |
|------|------------|------|
| inbox | **Git PR (입구)** | 기여자 PR → 메인테이너 머지 = 등재 |
| sources, wiki, adr | 없음 (내부) | 메인테이너 직접 push (PR 없이) |
| harness | **plugin 배포 (출구)** | 사용자는 이것만 받음 |

**inbox PR 워크플로우**
1. 기여자: `content/inbox/` 에 파일 추가 PR
2. 메인테이너: 리뷰 → 머지 = inbox 도착
3. **머지 ≠ 승격** — sources 로 올리는 건 별도 스킬

비개발 역할(QA/기획/PM/디자인 등 마찰 발생 시) 2번째 입구 (Issue → 메인테이너 카피) 추가 검토.

## Open Questions

- [ ] 비개발 PR 마찰이 실제 문제인지 운영 후 판단
