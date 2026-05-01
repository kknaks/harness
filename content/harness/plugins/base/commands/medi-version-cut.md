---
description: medi_docs/current/ 전체를 v{label}/ 으로 박제 (D1 강제 검증 + R4 동기화 + read-only)
---

`/medi:version-cut <label>` — 현재 작업 상태를 시점 박제한다.

- **label**: 사용자 자유 (`v1.0`, `2026Q2`, `release-2026-04` ...). semver 강제 X.

동작 (ADR-0008 §3 + ADR-0006 D-4):
1. **R4 collector 재실행** — cut 시점 plugin 풍경 (CLAUDE.md 마커 블록) 동결
2. **D1 강제 검증** — `current/` 전체 frontmatter 통과 필수, 실패 시 박제 차단
3. **`current/` → `v{label}/` 복사** — `_map.md` 함께 박제 (관계 그래프 동결)
4. **read-only 마크** — `chmod -R a-w v{label}/`
5. `current/` 그대로 유지 (carry-forward — ADR-0008 §2)

이후 `diff -r medi_docs/<prev>/ medi_docs/<label>/` 로 정책 변화 추적.

실행:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/medi-version-cut.sh" "$1"
```
