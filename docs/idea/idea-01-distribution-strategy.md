---
id: idea-01
type: idea
created: 2026-04-27
tags: [idea]
---

# Distribution Strategy

## 요구사항

1. 회사 Claude Code 사내 표준 배포
2. 다양한 스택 (Python, Bit, Next, Postgres 등)
3. 역할별 알맞은 skill set 자동 매핑 (frontend/backend/devops/...)
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
- `harness-base` (공통) + `harness-frontend` (Next) + `harness-backend-py` (Python/PG) + `harness-devops` ...
- 사용자: `claude plugin marketplace add github:<org>/harness` → 본인 역할 plugin 만 install
- `autoUpdate: true` 로 자동 갱신
- CI: PR 한 곳, CODEOWNERS 로 영역별 자동 리뷰어

## 왜 C

- 단일 repo = 단일 거버넌스 흐름 (PR/리뷰/CI 통일).
- 다중 plugin = 사용자 컨텍스트/스토리지 부담 최소화 (frontend 가 Python 스킬 안 받음).
- 마켓플레이스가 plugin 별 버전을 따로 추적.
- base 와 stack plugin 분리로 cross-cutting 룰 (커밋 컨벤션, 시크릿 훅) 을 한 곳에서.

## 구조 스케치

```
harness/                          # 사내 GitHub (private)
├── .claude-plugin/
│   └── marketplace.json          # 모든 plugin 등록
├── plugins/
│   ├── base/
│   │   ├── .claude-plugin/plugin.json
│   │   ├── skills/
│   │   ├── hooks/
│   │   └── CLAUDE.md
│   ├── frontend/
│   ├── backend-python/
│   ├── devops/
│   └── ...
├── CODEOWNERS                    # 영역별 자동 리뷰어
├── CONTRIBUTING.md               # PR 룰
└── .github/workflows/            # CI 검증, 자동 릴리즈
```

## Open Questions

- [ ] private GitHub repo 가능 여부 / 사내 git 인프라
- [ ] 역할 분류 기준 — frontend / backend-py / devops 외 더?
- [ ] `base` 에 들어갈 공통 항목 범위 (커밋 컨벤션, 시크릿 훅, 회사 CLAUDE.md, 공용 MCP)
- [ ] 신입 온보딩 자동화: `harness init` 같은 스크립트로 역할 선택 → plugin 자동 설치?
- [ ] base ↔ stack plugin 간 충돌 해결 룰 (예: hook 우선순위)
- [ ] plugin 간 버전 호환성 매트릭스 필요한가
- [ ] 지금 만든 idea→spec 도구 자체가 `base` 에 포함될 만한지 (사내 design doc 워크플로우로 유용)
- [ ] 비공개 MCP 서버는 plugin 에 포함할 수 있나, 아니면 별도 settings?
