---
name: code-review
description: 백엔드 변경분의 컨벤션 준수 + 설계 적정성 + 줄단위 보안/성능 점검을 4단계로 검토하고 심각도 5분류 (🔴blocking/🟡important/🟢nit/💡suggestion/🎉praise) 마크다운 리포트를 작성한다. 사용처 프로젝트의 `docs/common/*.md` + `CLAUDE.md` 를 trigger 시 reference 로 로드, 부재 시 role-generic fallback (MVC/계층화 일반 원칙) 으로 동작. PR 생성 전·새 도메인 구현 후·`/review` 슬래시 명령 호출 시 사용.
allowed_tools: [Read, Edit, Bash]
---

# Code Review

백엔드 코드 변경에 대한 *4단계 점검 → 심각도 분류 → 정형 리포트* 산출. 공용 골격 (어떤 백엔드 프로젝트든 적용) 과 프로젝트 컨벤션 (사용처에서 reference 로 로드) 을 분리해 동작.

## When to use

- `/review` 슬래시 명령
- PR 생성 전 코드 품질 자가 점검
- 새 도메인 구현 후 일관성 확인
- 변경 규모가 큰 작업의 분할·우선순위 판단

## How to invoke

```
/review                        # git diff 기반 변경 파일
/review path/to/file.py        # 특정 파일
/review {domain}               # 도메인 디렉토리 전체
```

후속:
1. **reference 로드** — 사용처 프로젝트의 `docs/common/*.md` + `CLAUDE.md` 가 있으면 컨벤션 슬롯 채움. 없으면 role-generic fallback (계층 분리·역방향 의존 금지·일반 보안/성능) 으로 진행.
2. **4단계 점검** — 맥락 파악 → 높은 수준 검토 → 줄단위 검토 → 요약 (자세한 phase 별 본질·시간 가이드는 `rules.md`).
3. **심각도 5분류 + 마크다운 리포트** — 이슈 ID (🔴 B-NNN / 🟡 I-NNN / 🟢 N-NNN) + Convention 출처 + Before/After. 🎉 praise 1건 이상 필수.

자세한 룰셋·심각도 기준·리포트 포맷·금지 사항은 [`rules.md`](rules.md). 운영 체크리스트는 [`checklist.md`](checklist.md). 실제 리포트 sample 은 [`examples/`](examples/).

## 보안 고려사항

- `allow_commands` 필요 X — read 만 (변경된 파일·diff·컨벤션 reference 읽기). 코드 수정은 사용자 손에 남김.
- 동적 입력 (파일 경로·도메인 slug) 은 `printf %q` 또는 quoted expansion (`"$VAR"`) 으로 인용. `../` 탈출 / 절대 경로 / 심볼릭 검증.
- `.env` / `secrets/` / token 파일은 review 대상에서 제외. 출력에 시크릿 포함 시 `***` 마스킹.
