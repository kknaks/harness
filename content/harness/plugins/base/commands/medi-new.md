---
description: medi_docs/ 에 새 문서 생성 (카테고리 + slug, template.md 시드, frontmatter id 자동)
---

`/medi:new <category> <slug>` — 새 문서를 박는다.

- **category**: planning / plan / spec / policy / adr / runbook / test / release-notes / retrospective
- **slug**: kebab-case (예: `customer-onboarding`)

동작:
1. `medi_docs/current/<category>/template.md` 를 시드로 복사
2. 다음 NN 자동 채움 (`<category>-NN-<slug>.md`)
3. frontmatter `id`, `created`, `updated` 자동 갱신
4. 사용자가 title + sources + 본문 채움

D4 강제: 비-planning 문서는 `sources:` 최소 1개 필요. 없으면 H1 hook 이 검증 차단.

실행:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/medi-new.sh" "$1" "$2"
```
