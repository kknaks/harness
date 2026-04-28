---
id: idea-03
type: idea
created: 2026-04-28
tags: [idea, scaffold]
related_to:
  - "[[idea-02-mediness-architecture]]"
---

# User Docs Scaffold

## 요구사항

1. 유저 (이 플러그인 사용자) 가 harness 를 설치/사용하면 자기 프로젝트에 `medi_docs/` 가 자동 생성
2. `medi_docs/docs/` 아래에 **버전별** 로 spec · 정책 · 기획 등 문서 생성용 디렉토리가 잡혀 있어야 함
3. 유저 목표 = **하네스 (코드 자동화) + 문서화 (설계·정책·기획 누적)** 둘을 한 플러그인에서 같이 제공

## 동기

- harness 가 코드 작성 스킬만 주면 반쪽. 의사결정·정책·기획을 쌓을 표준 자리가 없으면 각 팀이 제각기 docs 구조를 만들고, 결국 Claude 가 매 프로젝트마다 docs 구조를 새로 학습해야 한다.
- 버전별 디렉토리 = "v1.0 시점의 spec/정책/기획" 스냅샷 → 시간축 추적 가능.
- harness 의 메타 docs (idea-02 의 `docs/idea` `docs/spec`) 와 다른 레이어다. 이건 **유저 프로젝트가 받는 콘텐츠 docs**.

## 옵션 검토

### A. `/medi:init` 한 방에 ad-hoc 생성

- pro: 단순. skill 한 개.
- con: 일회성. 버전 관리 부재.

### B. install/첫 사용 시 scaffold + skill 로 버전 cut ← 추천

- 플러그인 install hook (또는 첫 skill 호출) 에서 `medi_docs/` 생성.
- `/medi:version-cut v1.0` → `current/` 내용을 `v1.0/` 으로 스냅샷.
- `current/` 는 항상 "작업 중인 다음 버전".

### C. 별도 generator CLI

- pro: harness 와 분리, 다른 도구에서도 재사용.
- con: "harness + 문서화 통합" 이라는 핵심 목표가 약해짐.

## 디렉토리 스케치

```
<user-project>/
└── medi_docs/
    ├── current/              # 작업 중인 다음 버전
    │   ├── spec/             # 명세
    │   ├── policy/           # 정책
    │   ├── planning/         # 기획
    │   └── _map.md           # auto
    ├── v1.0/                 # 잘라낸 버전 스냅샷
    │   ├── spec/
    │   ├── policy/
    │   └── planning/
    └── v0.9/
        └── ...
```

## 왜 `medi_docs` 인가

- harness 의 정체 (mediness, idea-02) 와 네이밍 일관성.
- 유저 프로젝트가 이미 `docs/` 를 가지는 경우가 흔함 → 충돌 회피용 별도 네임스페이스.

## 레이어 구분 (idea-02 와의 관계)

| 레이어 | 위치 | 누가 만지나 | 무엇 |
|--------|------|-------------|------|
| harness 메타 | (harness repo) `docs/idea` `docs/spec` | harness 메인테이너 | harness 자체에 대한 의사결정 |
| 유저 콘텐츠 | (user repo) `medi_docs/...` | 유저 팀 | 유저 프로젝트의 spec/정책/기획 |

→ 둘이 같은 작성 도구 (`docs-naming`, `docs-validate`, `promote-idea-to-spec`) 를 재사용할 수 있는지 검토 필요.

## 동작 흐름 (B 안 기준)

1. 유저가 harness plugin 설치
2. 첫 호출 시 (혹은 명시적 `/medi:init`) → `medi_docs/current/{spec,policy,planning}/` 생성, `_map.md` 초기화
3. 유저가 `current/` 안에서 자유롭게 문서 작성
4. 릴리즈 시점에 `/medi:version-cut v1.0` → `v1.0/` 디렉토리로 복사·동결, `current/` 는 다음 작업용으로 유지
5. 이후 `v1.0/` 은 read-only (수정 시 `v1.0.1` cut)

## Open Questions

- [ ] 버전 cut 트리거 — 수동 (skill 호출) vs git tag 연동 자동
- [ ] cut 직후 `current/` 는 — 비우기 / 그대로 유지 / 부분 carryover (정책별)
- [ ] 카테고리 분류 — `spec/policy/planning` 만? `adr/requirement/release-notes/runbook` 등 추가?
- [ ] `medi_docs` 도 `_map.md` 같은 자동 인덱스가 필요한가 → 그렇다면 harness 의 `docs-validate` 를 그대로 재사용 가능한가
- [ ] 버전 간 diff/lineage — "spec-03 이 v1.0 → v1.1 에서 어떻게 바뀌었나" 추적 필요?
- [ ] 유저 프로젝트의 기존 `docs/` 와 공존 — 별도 `medi_docs/` 네임스페이스로 분리하면 충분?
- [ ] scaffold 시점 — install hook (모든 사용자 강제) vs 첫 skill 호출 시 lazy
- [ ] role 분기 (idea-02 의 backend/frontend/...) 와 결합 — 역할별 정책 디렉토리가 필요한가, 아니면 정책은 역할 무관 공통인가
- [ ] `medi_docs/` 안에서도 idea→spec 흐름을 적용할까, 단순 카테고리 분류만 둘까
- [ ] 카테고리 디렉토리는 빈 채로 scaffold 할지, README/규칙 안내 파일을 같이 심을지
- [ ] 플러그인 제거 시 `medi_docs/` 처리 — 남김 (콘텐츠는 유저 자산) 이 자연스럽지만 명시 필요
