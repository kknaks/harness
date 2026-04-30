---
name: promote-docs
description: 메타·콘텐츠 레이어 문서를 한 단계 위로 승격(또는 기존에 병합) 한다. 메타: idea→spec→adr. 콘텐츠: inbox→sources→wiki→adr→harness. 모든 단계에 *생성 + 병합* 두 sh (ADR-0012 §2 피라미드 N→1 응축). 프론트매터의 sources 로 lineage, related_to/supersedes/depends_on 으로 그래프 관계 추적. 사용자가 "idea-NN 을 spec 으로", "inbox 자산을 sources 로", "sources-NN 을 wiki 로 합성" 같은 요청을 할 때 사용.
---

# Promote / Merge Docs

메타 lifecycle: `idea → spec → adr`. 콘텐츠 레이어: `inbox → sources → wiki → adr → harness`. 합쳐지거나, 중복으로 버려지거나, 일부만 위 단계로 굳는다.

## When to use

사용자가 다음 같은 요청 시:
- "idea-NN 을 spec 으로" / "spec-NN 을 ADR 로"
- "inbox 자산을 sources 로" / "sources-NN 을 wiki 로 합성" / "wiki-NN 을 ADR 로"
- "이 idea/sources 가 기존 spec/wiki 에 머지되나?"

## What it does

**머지 후보 검토 default** — 신규 vs 머지를 임의로 정하지 않고 항상 기존 후보부터 검토 (`docs/_map.md` / `content/_map.md` 의 owns / wiki / ADR 목록 → 사용자 명시 확인 → 분기). 매칭 시 「병합」 sh, 없으면 「생성」 sh.

자세한 절차·룰셋·스키마는 [`rules.md`](rules.md):
- §Promotion Flow / §Content Pipeline Flow §단계별 본질 + §합성 룰
- §자산 분리 룰 (wiki 두 층 → plugin 단계 처리)
- §frontmatter 두 facet (categories / role)
- §sh 호출 직전 사용자 확인 (필수 인자)
- §Steps (새 spec 승격 / 기존 spec 병합)
- §Frontmatter Schema / §Body Skeleton / §ADR Lifecycle / §Don't

## How to invoke

| 단계 | 신규 sh | 머지 sh |
|------|---------|---------|
| idea → spec | `idea-to-spec.sh <idea> [slug]` | `merge.sh <idea> <spec>` |
| spec → adr | `spec-to-adr.sh <spec> [slug]` | (supersedes 패턴 — `## Notes` append) |
| inbox → sources | `inbox-to-sources.sh <inbox> [slug]` | `merge-inbox-to-sources.sh` |
| sources → wiki | `sources-to-wiki.sh <sources> [slug]` | `merge-sources-to-wiki.sh <sources> <wiki>` |
| wiki → adr | `wiki-to-adr.sh <wiki> [slug] [role]` | (placeholder — supersedes 패턴) |
| adr → harness | `adr-to-harness.sh <adr> <plugin>` | — |

호출 직전 사용자 확인 — 메타 (`owns` + Scope) / 콘텐츠 ADR (`slug` + `role`). 자세히는 `rules.md` §sh 호출 직전 사용자 확인.

## 보안 고려사항

- `allow_commands` 필요 X — sh 들이 read/write 만 (git 명령 X).
- 동적 입력 (slug, role, 파일 경로) 은 sh 안에서 정규식 검증 + `printf %q` 인용.
- `docs/_map.md` / `content/_map.md` 직접 편집 금지 — 자동 생성물 (`docs-validate` 가 재생성).
