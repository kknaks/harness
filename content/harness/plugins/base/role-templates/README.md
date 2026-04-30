# Role Templates

`/harness:init <role>` 호출 시 *프로젝트의 `.claude/`* 로 복사되는 SKILL·command 자산. `harness` plugin 자체에서는 *비활성* — Claude Code 가 자동 활성하지 않음 (이 디렉토리는 plugin 의 표준 활성 위치 밖). 사용자가 명시적으로 `/harness:init` 호출 시에만 프로젝트로 복사되어 활성됨.

## 사용 가능한 role

| role | 포함 SKILL (v0.1) | depends_on | manifest |
|------|-------------------|-----------|----------|
| `backend` | `code-review`, `test-design` | _(none)_ | [`backend/role.json`](backend/role.json) |
| `frontend` | _(빈 role — v0.2+ 누적)_ | _(none)_ | [`frontend/role.json`](frontend/role.json) |
| `fullstack` | _(자체 SKILL 없음)_ | `backend`, `frontend` | [`fullstack/role.json`](fullstack/role.json) |
| `planner` | _(빈 role — v0.2+ 누적)_ | _(none)_ | [`planner/role.json`](planner/role.json) |
| `pm` | _(빈 role — v0.2+ 누적)_ | _(none)_ | [`pm/role.json`](pm/role.json) |
| `qa` | _(빈 role — v0.2+ 누적)_ | _(none)_ | [`qa/role.json`](qa/role.json) |
| `infra` | _(빈 role — v0.2+ 누적)_ | _(none)_ | [`infra/role.json`](infra/role.json) |

각 role 의 정확한 description / skill 목록은 manifest (`<role>/role.json`) 가 SSOT.

**`fullstack` 의 동작** — 자체 skill 없음. `depends_on: ["backend", "frontend"]` 로 두 role 의 skills 를 자동 흡수. `init.sh` 가 transitive expansion 으로 *backend SKILL + frontend SKILL* 을 복사 (dedup). 사용자는 단일 명령 (`/harness:init fullstack`) 으로 풀스택 셋업.

빈 role 은 `init` 시 SKILL 0개 복사 — 단, `medi_docs/` 9 카테고리 + 본 plugin 의 base hooks 는 박힘 (역할 무관 공통 자산).

## 호출

```
/harness:init backend          # backend role 의 SKILL 들 복사
/harness:init backend qa       # 다중 role
/harness:init backend --force  # 기존 파일 덮어쓰기 (업데이트 받을 때)
/harness:status                # 전체 상태 + 어떤 role 이 어떤 skill 가지는지 요약
```

## 디렉토리 구조

```
role-templates/
└── <role>/
    ├── role.json          ← 본 role 의 manifest (SSOT)
    ├── skills/
    │   └── <skill-name>/
    │       ├── SKILL.md   (ADR-0007 §1 표준)
    │       ├── rules.md
    │       ├── checklist.md
    │       └── examples/
    ├── commands/          (선택 — slash command 박을 거면 .md 파일들)
    │   └── <cmd-name>.md
    └── hooks/             (선택 — role 별 hook)
```

## role.json manifest 스키마

```json
{
  "role": "backend",
  "version": "0.1.0",
  "description": "한 줄 설명 — /harness:status 와 init 출력에 표시",
  "skills": ["code-review", "test-design"],
  "commands": [],
  "hooks": [],
  "depends_on": []
}
```

| 필드 | 필수 | 의미 |
|------|------|------|
| `role` | ✓ | role 슬러그 (디렉토리명과 일치) |
| `version` | ✓ | semver. plugin version (`plugin.json`) 따라가는 게 자연 |
| `description` | ✓ | 1줄 요약. status / init 출력에 표시 |
| `skills` | ✓ | 복사할 SKILL 이름 배열. 각 항목이 `skills/<name>/` 으로 실재해야 함. 빈 배열 가능 (만들고 있는 role) |
| `commands` | - | 복사할 slash command 이름 배열 (예: `["code-review", "test-design"]` → `commands/<n>.md` 파일이 있어야 함). v0.2 활성화 |
| `hooks` | - | 복사할 hook 이름 배열. v0.2 활성화 |
| `depends_on` | - | 의존하는 다른 role 이름 (예: `["base"]`). v0.2+ 검증 |

**manifest 우선** — `init.sh` 가 `role.json` 을 먼저 읽고 *명시된* skill 만 복사. manifest 부재 시 fallback (skills/ 디렉토리 전체 복사) — 마이그레이션 호환용.

**검증** — manifest 가 선언한 skill 이 실재 안 하면 `init.sh` 가 exit 3 + 에러 메시지. 운영 시 갱신 누락 잡힘.

## 새 role 추가 흐름

1. `mkdir role-templates/<new-role>/skills/`
2. `<skill-name>/` 디렉토리에 `create-skill.sh` (메인테이너 도구) 로 SKILL scaffold
3. `role-templates/<new-role>/role.json` 박음 (위 스키마)
4. 본 README 의 표 + ADR-0014 Notes 갱신
5. dogfood install + `/harness:init <new-role>` 검증

## ADR

- [[adr-0014-single-plugin-scaffolder]] — 본 모델 결정
- [[adr-0001-directory-structure]] — §부속결정 7-plugin supersede 박혀 있음
- [[adr-0007-skill-authoring-rules]] — 각 SKILL 의 표준 (4 필수 자산: SKILL.md / rules.md / checklist.md / examples/)
