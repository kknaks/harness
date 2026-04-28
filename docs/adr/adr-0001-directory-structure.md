---
id: adr-0001
title: Directory Structure
type: adr
status: proposed
date: 2026-04-28
sources:
  - "[[spec-02-directory-structure]]"
tags: [adr]
aliases: []
---

# Directory Structure

## Context

mediness 는 두 개의 서로 다른 레이어를 동시에 운영해야 한다.

- **콘텐츠 레이어**: 5단 파이프라인(inbox → sources → wiki → adr → harness). 사내 지식·자산이 정제·승격되는 라인.
- **메타 레이어**: 하네스 프로젝트 자체에 대한 의사결정(idea → spec → adr).

두 레이어는 lifecycle, 권한, 외부 노출 표면, 갱신 주기 모두 다르다. 한 디렉토리 안에 섞으면:
- 인덱스(_map.md)가 비대해지고 의미가 흐려진다.
- 검증·승격 도구가 두 lifecycle 을 동시에 처리해야 해 결합이 늘어난다.
- 권한 정책(콘텐츠 inbox 만 공용 vs 메타 전부 메인테이너)이 디렉토리 단위로 매핑 안 된다.

또한 메타 레이어도 ADR 도입으로 idea → spec → adr 3단으로 확장한다 (콘텐츠 5단의 idea·wiki·adr 와 어휘 대칭).

## Decision

**메타와 콘텐츠를 형제 디렉토리로 분리, 각자 자기 `_map.md` 를 보유한다.**

```
{repo-root}/
├── docs/                  ← 메타 (3단)
│   ├── _map.md
│   ├── idea/
│   ├── spec/
│   └── adr/
└── content/               ← 콘텐츠 (5단)
    ├── _map.md
    ├── inbox/
    ├── sources/
    ├── wiki/
    ├── adr/
    └── harness/
```

부속 결정:
- 두 `_map.md` 는 동일한 schema·format·검증 도구를 사용. `docs-validate` 가 두 루트를 각각 스캔해 두 인덱스를 독립 생성.
- 레이어 간 위키링크 참조는 원칙적으로 금지 (분리 유지).
- `harness/` 는 `content/` 안에 둔다 (배포 시 packaging 스크립트가 가져감). 레포 루트 노출 여부는 향후 별도 ADR 로 결정.

## Consequences

**Pros**
- 권한 정책이 디렉토리 단위로 깔끔히 매핑 (inbox 만 공용, 그 외 메인테이너).
- 두 레이어가 독립적으로 진화 가능 — 콘텐츠 도입이 메타 도구(`docs-validate` 등) 에 영향 없음.
- 사용자(plugin 소비자) 시야가 `harness/` 로 한정되어 노출 표면 단순.
- ADR 도입으로 메타·콘텐츠 어휘가 대칭 — 도구·관계 규칙 재사용성 ↑.

**Cons**
- `_map.md` 가 두 개 — 작업 시 두 인덱스를 봐야 함.
- `docs-validate` 가 두 루트 스캔하도록 확장 필요 (현재는 메타만 — 콘텐츠 운영 시작 시 일반화).
- 레이어 간 참조 금지 원칙이 실무에서 흐려질 위험 (예: 메타 idea 가 콘텐츠 wiki 를 참조하고 싶을 때).

**Follow-ups**
- 콘텐츠 레이어 가동 시 `docs-validate` 를 양쪽 루트 스캔하도록 확장.
- `harness/` 분리 노출 여부 결정 (별도 ADR).
- 레이어 간 참조가 정말 필요한 경우가 생기면 그때 별도 ADR 로 예외 규약 추가.

## Notes

_(시간순 append: status 전이, 적용 결과, 후속 학습, 관련 spec 추가 등)_

