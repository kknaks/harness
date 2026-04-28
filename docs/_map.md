# Docs Map

> 자동 생성. 수동 편집 금지. 재생성: `.claude/skills/docs-validate/scripts/validate.sh` (또는 docs/ 편집 시 자동 훅).

_13 spec(s), 4 idea(s), 1 adr(s), 0 unpromoted_

## Relations

### supersedes

_(없음)_

### depends_on

- [spec-10-medi-docs-scaffold](spec/spec-10-medi-docs-scaffold.md) → [spec-07-onboarding-skill](spec/spec-07-onboarding-skill.md)
- [spec-12-medi-docs-tooling](spec/spec-12-medi-docs-tooling.md) → [spec-02-directory-structure](spec/spec-02-directory-structure.md)
- [spec-12-medi-docs-tooling](spec/spec-12-medi-docs-tooling.md) → [spec-06-base-hoisting](spec/spec-06-base-hoisting.md)

### related_to

- [idea-01-distribution-strategy](idea/idea-01-distribution-strategy.md) ↔ [idea-02-mediness-architecture](idea/idea-02-mediness-architecture.md)
- [idea-02-mediness-architecture](idea/idea-02-mediness-architecture.md) ↔ [idea-03-user-docs-scaffold](idea/idea-03-user-docs-scaffold.md)
- [spec-03-frontmatter-naming](spec/spec-03-frontmatter-naming.md) ↔ [spec-11-medi-docs-frontmatter](spec/spec-11-medi-docs-frontmatter.md)
- [spec-03-frontmatter-naming](spec/spec-03-frontmatter-naming.md) ↔ [spec-13-skill-authoring-rules](spec/spec-13-skill-authoring-rules.md)
- [spec-10-medi-docs-scaffold](spec/spec-10-medi-docs-scaffold.md) ↔ [spec-11-medi-docs-frontmatter](spec/spec-11-medi-docs-frontmatter.md)
- [spec-10-medi-docs-scaffold](spec/spec-10-medi-docs-scaffold.md) ↔ [spec-12-medi-docs-tooling](spec/spec-12-medi-docs-tooling.md)
- [spec-11-medi-docs-frontmatter](spec/spec-11-medi-docs-frontmatter.md) ↔ [spec-13-skill-authoring-rules](spec/spec-13-skill-authoring-rules.md)

## Specs

| Topic | Status | Spec | Sources | Scope |
|-------|--------|------|---------|-------|
| base-hoisting | draft | [spec-06-base-hoisting](spec/spec-06-base-hoisting.md) | [idea-01-distribution-strategy](idea/idea-01-distribution-strategy.md) | `base` plugin 에 어떤 자산을 둘지 결정하는 정책 — 사전 분할 X, 운영 중 중복 발생 시 hoisting. 단계 간 승격(spec-05) 과 다른 차원 (plugin 자산 차원). |
| content-pipeline | draft | [spec-01-content-pipeline](spec/spec-01-content-pipeline.md) | [idea-02-mediness-architecture](idea/idea-02-mediness-architecture.md) | 5단 콘텐츠 파이프라인의 단계 의미·관계 규칙·6 role 분류. 단계별 동작·도구·디렉토리 명세는 다른 spec 에서. |
| directory-structure | draft | [spec-02-directory-structure](spec/spec-02-directory-structure.md) | [idea-02-mediness-architecture](idea/idea-02-mediness-architecture.md), [idea-01-distribution-strategy](idea/idea-01-distribution-strategy.md) | 하네스 레포의 디렉토리 트리 — docs/ + content/ + content/harness 의 plugin 모노레포 영역. 파일 컨벤션·권한·도구는 다른 spec. |
| frontmatter-naming | draft | [spec-03-frontmatter-naming](spec/spec-03-frontmatter-naming.md) | [idea-02-mediness-architecture](idea/idea-02-mediness-architecture.md) | 5단 콘텐츠 + 3단 메타의 파일명 패턴, 공통/단계별 프론트매터 필드, 단계별 본문 스켈레톤(spec, adr). |
| hook-precedence | draft | [spec-08-hook-precedence](spec/spec-08-hook-precedence.md) | [idea-01-distribution-strategy](idea/idea-01-distribution-strategy.md) | 여러 plugin 의 hook 이 같은 이벤트에 등록될 때 실행 순서 정책. base ↔ role 계층 + 다중 role 보유 시 role 간 정렬. 권한 정책(spec-04)·자산 hoisting(spec-06) 과 다른 차원. |
| medi-docs-frontmatter | draft | [spec-11-medi-docs-frontmatter](spec/spec-11-medi-docs-frontmatter.md) | [idea-03-user-docs-scaffold](idea/idea-03-user-docs-scaffold.md) | medi_docs 9 카테고리의 frontmatter 필드 + 본문 스켈레톤 + 검증 차등. 메타·콘텐츠 frontmatter 는 [[spec-03-frontmatter-naming]]. |
| medi-docs-scaffold | draft | [spec-10-medi-docs-scaffold](spec/spec-10-medi-docs-scaffold.md) | [idea-03-user-docs-scaffold](idea/idea-03-user-docs-scaffold.md) | 사용자 프로젝트 `medi_docs/` 의 디렉토리 구조 (9 카테고리, `current/` + `v{label}/` 버전 모델), scaffold 시점, cut 동작, uninstall 처리. frontmatter·template 구체와 도구 셋 명세는 분리. |
| medi-docs-tooling | draft | [spec-12-medi-docs-tooling](spec/spec-12-medi-docs-tooling.md) | [idea-03-user-docs-scaffold](idea/idea-03-user-docs-scaffold.md) | 사용자 배포본 도구 셋(`/medi:new` · `/medi:version-cut` · `docs-validate`)의 인터페이스·동작·base plugin 패키징을 명세한다. 메인테이너용 도구(`docs-naming`, `promote-docs`, 메인테이너용 `docs-validate`)는 이 spec 의 대상이 아니다. |
| onboarding-skill | draft | [spec-07-onboarding-skill](spec/spec-07-onboarding-skill.md) | [idea-01-distribution-strategy](idea/idea-01-distribution-strategy.md) | 사용자(신입·기존)의 mediness plugin 셋업·역할 변경·동기화·정리를 처리하는 단일 대화형 스킬 (`harness`). 메인테이너용 단계 간 승격 스킬(spec-05)과는 다른 도구. |
| permissions-flow | draft | [spec-04-permissions-flow](spec/spec-04-permissions-flow.md) | [idea-02-mediness-architecture](idea/idea-02-mediness-architecture.md) | 단계별 쓰기 권한과 외부 노출 표면(inbox PR 입구, harness plugin 출구). hook 실행 순서는 spec-08 참고. |
| promote-skills | draft | [spec-05-promote-skills](spec/spec-05-promote-skills.md) | [idea-02-mediness-architecture](idea/idea-02-mediness-architecture.md) | 단계 간 승격을 처리하는 스킬·스크립트 (idea→spec, spec→adr 등). 사용자 온보딩 스킬은 별개. |
| skill-authoring-rules | draft | [spec-13-skill-authoring-rules](spec/spec-13-skill-authoring-rules.md) | [idea-04-skill-authoring-rules](idea/idea-04-skill-authoring-rules.md) | `.claude/skills/*/SKILL.md` 의 frontmatter 스키마 + 본문 규칙 + 보안 정책 + 검증 룰셋. 메타·콘텐츠 docs (`docs/idea`, `docs/spec`, `docs/adr`) 의 frontmatter 는 [[spec-03-frontmatter-naming]] 가 다룸 — 검증 대상이 다름. |
| version-rollout | draft | [spec-09-version-rollout](spec/spec-09-version-rollout.md) | [idea-01-distribution-strategy](idea/idea-01-distribution-strategy.md) | plugin 버전 갱신·릴리즈·롤백 정책. autoUpdate 운영 + 단계 release(CI → dogfood → release → 문제 시 force update). 호환성 매트릭스는 운영 X. |

## Ideas (lineage view)

| File | Status | Absorbed into |
|------|--------|---------------|
| [idea-01-distribution-strategy](idea/idea-01-distribution-strategy.md) | absorbed | [spec-06-base-hoisting](spec/spec-06-base-hoisting.md), [spec-02-directory-structure](spec/spec-02-directory-structure.md), [spec-08-hook-precedence](spec/spec-08-hook-precedence.md), [spec-07-onboarding-skill](spec/spec-07-onboarding-skill.md), [spec-09-version-rollout](spec/spec-09-version-rollout.md)  ⚠ multi-spec |
| [idea-02-mediness-architecture](idea/idea-02-mediness-architecture.md) | absorbed | [spec-01-content-pipeline](spec/spec-01-content-pipeline.md), [spec-02-directory-structure](spec/spec-02-directory-structure.md), [spec-03-frontmatter-naming](spec/spec-03-frontmatter-naming.md), [spec-04-permissions-flow](spec/spec-04-permissions-flow.md), [spec-05-promote-skills](spec/spec-05-promote-skills.md)  ⚠ multi-spec |
| [idea-03-user-docs-scaffold](idea/idea-03-user-docs-scaffold.md) | absorbed | [spec-11-medi-docs-frontmatter](spec/spec-11-medi-docs-frontmatter.md), [spec-10-medi-docs-scaffold](spec/spec-10-medi-docs-scaffold.md), [spec-12-medi-docs-tooling](spec/spec-12-medi-docs-tooling.md)  ⚠ multi-spec |
| [idea-04-skill-authoring-rules](idea/idea-04-skill-authoring-rules.md) | absorbed | [spec-13-skill-authoring-rules](spec/spec-13-skill-authoring-rules.md) |

## ADRs

| Status | Date | ADR | Source spec |
|--------|------|-----|-------------|
| proposed | 2026-04-28 | [adr-0001-directory-structure](adr/adr-0001-directory-structure.md) | [spec-02-directory-structure](spec/spec-02-directory-structure.md) |
