---
name: promote-docs
description: 메타·콘텐츠 레이어 문서를 한 단계 위로 승격(또는 기존에 병합) 한다. 현재 지원: idea→spec, spec→adr. 프론트매터의 sources 로 lineage, related_to/supersedes/depends_on 으로 그래프 관계 추적. 사용자가 "idea-NN 을 spec 으로", "spec-MM 을 ADR 로", "idea-NN 을 spec-MM 에 합쳐" 같은 요청을 할 때 사용.
---

# Promote / Merge Docs

메타 lifecycle: `idea → spec → adr`. 향후 콘텐츠 레이어: `inbox → sources → wiki → adr → harness`. 합쳐지거나, 중복으로 버려지거나, 일부만 위 단계로 굳는다. 추적은 산출 문서 프론트매터의 다음 필드들로:

- `sources` (필수, 1개 이상) — 흡수한 idea 위키링크 리스트 (lineage)
- `related_to` (선택) — 양방향 소프트 링크
- `supersedes` (선택) — 단방향 하드 링크 (이 spec 이 다른 문서를 대체)
- `depends_on` (선택) — 단방향 의존 관계

`docs/_map.md` 의 Relations 섹션이 이 모두를 양방향 인덱싱 (`docs-validate` 가 자동 재생성).

## Promotion Flow (모든 promote 요청 시작점)

신규 vs 머지를 임의로 정하지 말고 **항상 머지 후보 검토부터**:

1. **머지 후보 검토** — `docs/_map.md` 의 Specs (또는 ADRs) 섹션에서 기존 `owns` 목록을 본다.
2. **각 후보 spec 의 본문 `## Scope`** 를 읽어 의도 범위 확인.
3. **사용자 확인** — "이 idea 의 토픽이 spec-XX(`owns: foo`) 와 겹치나?" 명시적으로 묻기. 직감 X.
4. **분기**:
   - 매칭됨 → 「기존 spec 에 병합」 절차
   - 매칭 안 됨 → 「새 spec 으로 승격」 절차

머지 후보 검토는 default. 신규 생성은 매칭 없을 때만.

idea 파일은 항상 보존. 추적의 단방향 진실은 spec 의 frontmatter.

## Steps — 새 spec 으로 승격

(Promotion Flow 의 머지 후보 검토 후, 매칭 없을 때만)

1. **소스 확인** — idea 파일 존재 + `id`/`type` 프론트매터 보유.
2. **`owns` + Scope 합의** — 사용자와 (1) topic 이름(kebab-case) + (2) **Scope 한 줄**: 이 spec 이 다루는 범위. 다음번 머지 판단의 기준이 된다.
3. **스캐폴드** — `scripts/idea-to-spec.sh <idea> [slug]` → 9개 필수 필드 + Scope 슬롯 포함.
4. **본문 채우기** — `## Scope` 한 줄 작성 후 나머지 섹션.
5. **(선택) 관계** — `related_to`/`supersedes`/`depends_on` 필요 시 손으로 추가.
6. **검증 + _map 재생성** — `docs-validate/scripts/validate.sh`.
7. **보고** — 경로, owns, Scope, 검증 결과.

## Steps — 기존 spec 에 병합

1. **대상 확인** — idea + spec 둘 다 존재.
2. **Scope 확인** — spec 의 `## Scope` 가 idea 토픽을 포괄하는가?
   - 포괄 → 그대로 머지.
   - 부분 포괄 → spec.Scope 를 확장하는 게 자연스러운가? 아니면 신규?
   - 사용자에게 명시적으로 확인.
3. **머지** — `scripts/merge.sh <idea> <spec>` → spec 의 `sources` 에 추가, `updated` 갱신.
4. **본문 통합** — idea 의 핵심을 spec 본문에 반영. Scope 확장이 필요하면 같이 갱신.
5. **검증 + _map 재생성** — `docs-validate/scripts/validate.sh`.
6. **보고** — 갱신된 sources, Scope 변경 여부, _map 변경.

## Frontmatter Schema (spec)

`examples/spec-01-cli-shape.md` 가 정본 (관계 4종 모두 포함한 예).

| 필드 | 필수 | 값 |
|------|------|-----|
| `id` | ✓ | `spec-NN` |
| `title` | ✓ | 제목 |
| `type` | ✓ | `spec` |
| `status` | ✓ | `draft` \| `active` \| `decided` \| `deprecated` |
| `created` | ✓ | `YYYY-MM-DD` |
| `updated` | ✓ | `YYYY-MM-DD` |
| `sources` | ✓ | 흡수한 idea 위키링크 리스트 (1개 이상) |
| `owns` | ✓ | SSOT topic (유일) |
| `tags` | ✓ | 최소 `[spec]` |
| `aliases` | - | Obsidian alias |
| `related_to` | - | 양방향 소프트 링크 (idea/spec 모두 가능) |
| `supersedes` | - | 이 spec 이 대체하는 문서 |
| `depends_on` | - | 이 spec 이 의존하는 spec |

`sources` 블록 형식:
```yaml
sources:
  - "[[idea-02-cli-shape]]"
  - "[[idea-07-shell-completion]]"
```

## Body Skeleton

**spec** (Scope + 6 필수 + 2 선택):
```
# <Title>

## Scope             ← 이 spec 이 다루는 범위 (1~2문장). 머지 판단 기준. _map.md 에 노출됨.
## Summary           ← 1~2문장 TL;DR
## Background        ← sources idea 핵심 발췌, 동기
## Goals             ← 달성 목표 (불릿)
## Non-goals         ← 명시 제외 (불릿)
## Design            ← 구체 설계
## Open Questions    ← 미결 (체크박스)

<!-- 선택 (해당 시 주석 해제) -->
<!-- ## Interface              ← CLI / API / 파일 포맷 -->
<!-- ## Alternatives Considered ← 대안 후보 + 채택 안 한 이유 -->
```

**adr** (Michael Nygard 표준 + Notes 확장):
```
# <Title>

## Context
## Decision
## Consequences
## Notes        ← 시간순 append (status 전이, 적용 결과, 후속 학습)
```
- status / date 는 frontmatter.
- 결정 자체가 뒤집히면 새 ADR + `supersedes` 로 옛것 대체.
- sources 는 불변 lineage. 이후 추가 관련 spec 은 Notes 로 참조.

## Source spec status 전이 (spec→adr 시)

`spec-to-adr.sh` 는 ADR 만 생성 (status=`proposed`). **source spec status 는 자동 갱신 X** — 흡수 패턴이 케이스마다 다르기 때문. 메인테이너가 ADR lifecycle 진행에 따라 수동 갱신:

| 흡수 패턴 | source spec status | 시점 |
|-----------|---------------------|------|
| spec 통째로 한 ADR | `decided` | ADR 가 `accepted` 된 시점 |
| spec 의 일부 결정만 ADR (다른 부분 운영 명세로 살아있음) | `active` | ADR 가 `accepted` 된 시점 |
| spec 이 새 ADR/spec 으로 supersede | `deprecated` | supersede ADR/spec 이 `accepted` 된 시점 |

ADR 가 `proposed` 단계 (검토 중) 에는 source spec 그대로 (`draft` or `active`). ADR 가 `accepted` 로 굳을 때 위 표대로 spec 갱신.

ADR status 전이 자체:
- `proposed` — scaffold 직후. 검토 중.
- `accepted` — 메인테이너 합의 완료. 결정 효력 발휘. source spec status 도 같이 갱신.
- `superseded` — 새 ADR 가 `supersedes` 로 대체.
- `deprecated` — 더 이상 안 씀 (대체 ADR 없이 폐기).

## ADR Lifecycle — 관련 사항이 추가될 때

ADR 본문(Decision)은 **immutable** — 한 번 적힌 결정 텍스트는 거의 안 건드린다. 변화는 (1) `## Notes` append, (2) 새 ADR + 관계 필드, 둘 중 하나.

| 상황 | 처리 |
|------|------|
| 같은 결정 + 후속 학습·적용 결과 | 기존 ADR 의 `## Notes` 에 시간순 append |
| 같은 결정 + 관련 spec 추가 발견 | Notes 에 `[[spec-XX]]` 참조 (sources 는 불변) |
| status 전이만 (proposed → accepted 등) | frontmatter `status` + `date` 갱신, Notes 1줄 |
| 결정이 뒤집힘 / 대체 | 새 ADR + `supersedes: [[adr-NNNN-...]]` |
| 기존 결정 위에 부속 결정 | 새 ADR + `depends_on: [[adr-NNNN-...]]` |
| 비슷한 영역, 무관한 결정 | 새 ADR + (선택) `related_to: [[adr-NNNN-...]]` |

**자동 처리**: 관계 4종(`sources`/`related_to`/`supersedes`/`depends_on`) 만 쓰면 `_map.md` 가 자동 인덱싱하고 `validate.py` 가 사이클·끊긴 링크 잡는다.

**경계 신호**:
- Notes 가 너무 길어진다 → 새 결정으로 분기 시점
- 같은 영역에 ADR 3개+ → 상위 spec 재정리 시점

## Scripts

**메타 레이어** (`docs/`)
- `scripts/idea-to-spec.sh <idea> [slug]` — idea → 새 spec 생성. **`[slug]` 옵션** 으로 1 idea → N specs 분할 시 충돌 방지 (kebab-case).
- `scripts/spec-to-adr.sh <spec> [slug]` — spec → 새 ADR 생성 (`docs/adr/adr-NNNN-{slug}.md`, status=proposed, body=Context/Decision/Consequences).
- `scripts/merge.sh <idea> <spec>` — 기존 spec 의 sources 에 idea 추가 (멱등).

**콘텐츠 레이어** (`content/`, adr-0003)
- `scripts/inbox-to-sources.sh <inbox-file> [slug]` — raw inbox 자산 → `content/sources/sources-NN-<slug>.md` (정체화 + 불변 박제). 본문은 *정체* (이름·목적) scaffold.
- `scripts/sources-to-wiki.sh <sources-file> [slug]` — sources → `content/wiki/wiki-NN-<slug>.md` (합성 scaffold). 실제 합성 본문은 Claude 가 채움.
- `scripts/wiki-to-adr.sh <wiki-file> [slug]` — wiki → `content/adr/adr-NNNN-<slug>.md` (콘텐츠 ADR, 메타 ADR 카운터와 분리).
- `scripts/adr-to-harness.sh <content-adr> <plugin-name>` — ADR → plugin 적용 (Notes 에 lineage 기록만; 패키징은 spec-09 release flow 영역).

**1 idea → N specs 예시**:
```
idea-to-spec.sh docs/idea/idea-02-mediness-architecture.md content-pipeline
idea-to-spec.sh docs/idea/idea-02-mediness-architecture.md directory-structure
# ...
```

## Checklist

`checklist.md`.

## Don't

- idea 파일 삭제 금지 — 모든 관계 위키링크가 끊김.
- `docs/_map.md` 직접 편집 금지 — 자동 생성물.
- 동일 `owns` 가 다른 spec 에 있으면 새로 만들지 말고 병합.
- `supersedes`/`depends_on` 사이클 금지 — validate 가 잡지만 처음부터 만들지 말 것.
- 번호 재사용 금지.
