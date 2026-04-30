# Role Templates

`/harness init <role>` 호출 시 *프로젝트의 `.claude/skills/`* 로 복사되는 SKILL 자산. `harness` plugin 자체에서는 *비활성* — Claude Code 가 자동 활성하지 않음 (이 디렉토리는 plugin 의 표준 활성 위치 밖). 사용자가 명시적으로 `/harness init` 호출 시에만 프로젝트로 복사되어 활성됨.

## 사용 가능한 role

| role | 포함 SKILL | 설명 |
|------|------------|------|
| `backend` | `code-review`, `test-design` | API 설계 / DB / Python·PostgreSQL 컨벤션. 사용처 프로젝트의 `docs/common/*.md` 를 reference 로 로드 |
| `frontend` | _(v0.1 미박. v0.2+)_ | 컴포넌트·상태 관리·접근성 |
| `planner` | _(v0.1 미박. v0.2+)_ | 기획서 / 정책 문서 |
| `pm` | _(v0.1 미박. v0.2+)_ | 일정 / 우선순위 / 릴리즈 트래킹 |
| `qa` | _(v0.1 미박. v0.2+)_ | 테스트 전략 / 회귀 분석 |
| `infra` | _(v0.1 미박. v0.2+)_ | 배포 / 인프라 / 모니터링 |

## 호출

```
/harness init backend          # backend role 의 SKILL 들 복사
/harness init backend qa       # 다중 role
/harness init backend --force  # 기존 파일 덮어쓰기 (업데이트 받을 때)
```

## 디렉토리 구조

```
role-templates/
└── <role>/
    └── skills/
        └── <skill-name>/
            ├── SKILL.md       (ADR-0007 §1 표준)
            ├── rules.md
            ├── checklist.md
            └── examples/
```

`<role>/hooks/` 등 추가 자산도 있을 수 있음 (있으면 `.claude/hooks/` 로 함께 복사).

## ADR

- [[adr-0014-single-plugin-scaffolder]] — 본 모델 결정
- [[adr-0001-directory-structure]] — 7-plugin 결정 supersede 박혀 있음
