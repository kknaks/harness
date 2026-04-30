# harness

mediness 사내 공용 하네스 — **단일 plugin + role-templates scaffolder** ([[adr-0014-single-plugin-scaffolder]]). plugin 자체는 전역에 한 번 install, role 자산은 `/harness init <role>` 호출 시 *프로젝트의 `.claude/`* 로 복사.

## 자산

| 위치 | 역할 | 활성/비활성 |
|------|------|-------------|
| `plugin.json` | manifest (`autoUpdate`, `mcpServers.harness-github`) | 활성 |
| `hooks/hooks.json` | H1 medi_docs 자동 검증 · H4 시크릿 차단 · H5 환경 검증 (ADR-0009 §1) | 활성 (전역) |
| `skills/harness/` | `/harness` 사용자 진입점 (`init` / 상태 확인) — ADR-0006 / ADR-0014 | 활성 |
| `scripts/scaffold-medi-docs.sh` | 9 카테고리 `medi_docs/current/` 박기 (ADR-0008 §4) | 호출형 (init 이 호출) |
| `medi-docs-templates/` | 9 카테고리 README + template — 사용자 cwd scaffold 자산 (ADR-0008 §1) | 데이터 |
| `role-templates/<role>/skills/` | role 별 SKILL 템플릿 — Claude Code 자동 활성 *밖* | **비활성** (init 이 복사 시점에 활성화) |

## 사용자 흐름

```
1. /plugin marketplace add https://github.com/kknaks/harness
   (v0.1 dogfood — 사내 mediness 배포 전 임시 origin. 정식 origin 은 v1.0 cutover 시점)

2. /plugin install harness
   (전역, 한 번만)

3. <프로젝트 디렉토리에서 Claude Code 세션>
   /harness init backend
   (또는 다중: /harness init backend qa)
   → .claude/skills/code-review/, .claude/skills/test-design/ 박힘
   → medi_docs/current/{adr,plan,planning,...}/ 9 카테고리 박힘

4. /code-review src/api/branch.py
   (프로젝트 로컬 SKILL 호출)
```

## 갱신

메인테이너가 SKILL 갱신:
```
/plugin update harness          (plugin 본체 갱신 — autoUpdate)
/harness init backend --force   (프로젝트의 .claude/skills/<n>/ 덮어쓰기)
```

기본 `init` 은 *기존 파일이 있으면 skip* (사용자 커스텀 보존). `--force` 시에만 덮어쓰기. 사용자가 `.claude/skills/<n>/rules.md` 를 직접 편집했다면 git 으로 추적 → `--force` 전에 commit / stash 후 머지 책임.

세밀한 sync (보편 슬롯만 갱신, 사용자 § 보존) 는 v0.2 follow-up — 메인테이너의 `sync-skill` 패턴 차용 예정 (ADR-0014 §Follow-ups).

## 사용 가능한 role (v0.1)

| role | SKILL | 호출 |
|------|-------|------|
| `backend` | `code-review`, `test-design` | `/code-review`, `/test-design` |

frontend / planner / pm / qa / infra 는 v0.2+ 누적 (ADR-0014 §Follow-ups, [`role-templates/README.md`](role-templates/README.md)).

## Uninstall

```
# 프로젝트의 .claude/skills/<n>/ 제거
rm -rf .claude/skills/code-review .claude/skills/test-design
# (medi_docs/ 는 사용자 자산 — 필요 시 직접 rm)

# plugin 자체 제거 (전역)
/plugin uninstall harness
```

> Claude Code plugin manifest 가 uninstall hook native 미지원 — 본 README 안내로 대체 (ADR-0008 §5).

## 더 보기

- mediness 전체 구조: harness repo `docs/_map.md` (메타) + `content/_map.md` (콘텐츠 5단)
- 결정 박제: `docs/adr/` — 핵심 ADR-0014 (본 모델), ADR-0001 (디렉토리 구조), ADR-0007 (SKILL 작성 표준)
- 자산-plugin 매핑: `content/adr/` (콘텐츠 ADR — code-review-to-backend, test-design-to-backend)
