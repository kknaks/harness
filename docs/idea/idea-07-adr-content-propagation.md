---
id: idea-07
type: idea
status: rejected
created: 2026-05-01
tags: [idea]
related_to:
  - "[[adr-0003-content-pipeline]]"
  - "[[adr-0004-frontmatter-naming]]"
  - "[[adr-0008-medi-docs-scaffold]]"
  - "[[adr-0012-promote-skills]]"
---

# ADR 결정 → 콘텐츠 자산 Propagation

## Problem

메타 ADR 결정이 콘텐츠 자산 (`content/harness/...`) 본문에 자동으로 반영되는 메커니즘이 없다. 메인테이너가 ADR 만 patch 하고 끝나면 dependent 콘텐츠 자산이 silently stale.

**구체 사례** (2026-05-01 발견)

`ADR-0008` (medi-docs-scaffold) 가 2026-04-29 에 §7 (진입점·lineage 위계) + §6 D4 (lineage 필수 차단 룰) 를 추가:

- planning 이 SSOT root
- 비-planning 문서는 `sources:` 최소 1개
- 위계는 frontmatter `sources:` 그래프로만 표현

근데 같은 시점에 `content/harness/plugins/base/medi-docs-templates/` 의 자산들은 갱신 안 됨:

| 자산 | §7 결정 반영? |
|---|---|
| `medi_docs/README.md` (루트 진입점) | 부재 (없음) |
| `{category}/README.md` 9개 | 카테고리 1줄 설명만, lineage 안내 X |
| `{category}/template.md` frontmatter `sources:` | `[[<upstream>]]` placeholder, 카테고리별 구체화 X |
| `scaffold-medi-docs.sh` 가 만드는 `_map.md` | "자동 생성 placeholder" 한 줄 |

결과: 사용자가 medi_docs/ 받으면 SSOT 위계를 알 방법이 없다 (메인테이너 머릿속 ADR-0008 §7 에만 존재).

## 근본 원인

- **메타→콘텐츠 propagation 단계 부재** — ADR 결정이 박힐 때 dependent 콘텐츠 자산을 stale 로 마킹하거나 patch PR 을 강제하는 메커니즘이 파이프라인에 없음.
- **frontmatter 어휘 부재** — 콘텐츠 자산이 어떤 ADR 의 어떤 결정을 implement 하는지 추적할 어휘 없음 (관계 4종 `sources/related_to/supersedes/depends_on` 으로는 의미 부족).
- **검증 범위 부재** — `docs-validate` 가 frontmatter 정합성만 보고, "ADR §X 의 결정이 콘텐츠 자산 본문에 박혔는지" 는 안 봄.

5단 파이프라인 (ADR-0003: inbox→sources→wiki→adr→harness) 은 *콘텐츠 자체의 N→1 응축* 을 잡지만, *메타 ADR → 콘텐츠 자산 갱신* 은 잡지 않는다. 둘이 평행하게 진행되고 만남을 메인테이너 자기 규율에 맡기는 구조.

## 해결 후보

| # | 어디 | 무엇 | 비용 |
|---|---|---|---|
| **C1** | frontmatter | 콘텐츠 자산에 `implements: [[adr-NNNN#section]]` 어휘 추가 (ADR-0004 R4-R9 enum 확장) | 작음. 어휘 1개 추가 |
| **C2** | `validate.py` | ADR `mtime` > implementing 콘텐츠 자산 `updated` 일 때 stale 차단/경고 | C1 의존. 중간 |
| **C3** | PostToolUse 훅 | `docs/adr/*` 변경 시 implements 역참조 자산 목록 stdout 출력 → 메인테이너 알림 | C1 의존. 작음 |
| **C4** | promote-docs | `adr-to-content.sh` — ADR 변경 후 dependent 콘텐츠 자산 patch PR 시그널 생성 | C1+C3 위에. 큼 |

가장 작은 진입점은 **C1 + C2 + C3 셋트** — 어휘 + stale 차단 + 알림. C4 는 운영 후 결정.

## Open Questions

- [ ] **OQ1** `implements` 어휘를 ADR-0004 R4-R9 에 추가할 때 enum 위치 (관계 4종에 5번째? 별도 섹션?)
  - 후보 A: 관계 4종 확장 (`sources/related_to/supersedes/depends_on/implements`) — 일관성
  - 후보 B: 별도 어휘 카테고리 (관계 = lineage, implements = 결정-구현 매핑) — 의미 분리
  - 결정 원칙: 관계 4종은 *동종 자산 간 lineage*, implements 는 *메타→콘텐츠 cross-layer* — 의미 다름. **후보 B** 가 정합. (이 결정은 spec 단계에서 박을 것)

- [ ] **OQ2** stale 판정 기준 (C2)
  - mtime 만? frontmatter `updated` 만? 둘 다?
  - ADR 의 어느 변경이 stale 트리거? Notes append 도 stale? (당연히 X — Decision 본문 수정만)
  - 결정 원칙: **frontmatter `updated` + Decision 본문 hash 기반**. Notes append 는 trigger X. (spec 에서 명세)

- [ ] **OQ3** 차단 vs 경고 (C2)
  - stale 콘텐츠 자산 발견 시 `validate.py` 가 차단? 경고만?
  - 결정 원칙: 메인테이너 작업장이라 차단까진 과함. **경고 + PostToolUse 훅에서 노출** (C3 와 결합). 차단은 release cut 시점에만.

- [ ] **OQ4** 5단 파이프라인 (inbox→sources→wiki→adr→harness) 자산 모두 적용? 아니면 `harness/` (final stage) 만?
  - 결정 원칙: **`harness/` 만**. 중간 단계 (inbox/sources/wiki) 는 자체 lifecycle 진행 중이라 ADR 반영 의무 없음. final stage = 사용자 배포본만 stale 검증.

- [ ] **OQ5** 기존 콘텐츠 자산 retrofit 범위
  - 현재 `content/harness/plugins/base/` 의 모든 자산에 `implements:` 박는 큰 작업
  - 또는 신규 자산부터 점진 도입
  - 결정 원칙: **기존 medi-docs-templates 만 우선 retrofit** (지금 바로 stale 인 곳). 나머지는 신규부터.

## Related

- [[adr-0003-content-pipeline]] — 5단 파이프라인 자체. 이 idea 는 그 위에 메타→콘텐츠 cross-layer 추가.
- [[adr-0004-frontmatter-naming]] R4-R9 — `implements` 어휘 추가 위치.
- [[adr-0008-medi-docs-scaffold]] §7 — 이 idea 가 catch 했어야 할 stale 사례의 진원지.
- [[adr-0012-promote-skills]] — promote-docs 의 메타+콘텐츠 두 파이프라인 정의. C4 (`adr-to-content.sh`) 가 여기 추가될 후보.

## Notes

- 2026-05-01: 사용자 발견. ADR-0008 §7 결정이 medi-docs-templates 에 안 내려간 것을 catch 하면서 *propagation 메커니즘 자체 부재* 가 진짜 갭임을 확인. 메모리 feedback ("파이프라인 로직만 수정") 과 같은 라인의 갭.
- 2026-05-01: **status: open → rejected.** 잘못된 진단. propagation 메커니즘은 이미 박혀 있음 (frontmatter 4종 관계 + `_map.md` auto-regen + ADR-0008 §6 D4 multi-target 룰). 새 어휘 (`implements:`) 도 불필요 — 같은 `sources:` 그래프가 모든 레이어에 적용되면 끝. 진짜 갭은 별도 문서 (정리 후 박을 예정).

