---
name: backend-rules
description: 백엔드 작업 라이프사이클 4단계 (설계 → Red → Green → Refactor) + 4계층 아키텍처 정렬. /backend-rules <단계> 로 호출, 사용처의 plan/api/, plan/design-standards/, plan/erd/, CLAUDE.md 를 reference 로 로드
allowed_tools: [Read, Edit, Bash]
---

# Backend Rules

백엔드 도메인 작업의 *라이프사이클 4단계* (설계 → Red → Green → Refactor) + 4계층 아키텍처 정렬 진행. 사용처 프로젝트의 reference 문서 (`plan/api/`, `plan/design-standards/`, `plan/erd/`, `CLAUDE.md`) 를 trigger 시 로드, 부재 시 role-generic fallback (REST 일반 원칙·SOLID·일반 디렉토리 추정) 으로 동작. 자매 SKILL [`code-review`](../code-review/) (사후 검토) / [`test-design`](../test-design/) (사전 시나리오 설계) 와 분리 패턴 동일.

## When to use

- `/backend-rules <단계>` 슬래시 명령 (단계 = `api-design` / `tdd-cycle` / `refactor-layered`)
- 새 도메인·API 시작 — 라이프사이클 1번부터 진행
- 기존 도메인 수정 — 어느 단계부터인지 합의 후 진행
- 4계층 위반 점검 — `refactor-layered` 단독 호출

## How to invoke

```
/backend-rules api-design <domain>          # 1단계: 엔드포인트 설계 + plan/api/<domain>.md 갱신
/backend-rules tdd-cycle <domain>           # 2-3단계: Red → Green
/backend-rules refactor-layered <router>    # 4단계: 4계층 정렬
/backend-rules                              # 인자 없으면 라이프사이클 안내 + 단계 결정 guide
```

후속:
1. **reference 로드** — 사용처 `plan/api/*.md` + `plan/design-standards/*.md` + `plan/erd/*.md` + `CLAUDE.md` 가 있으면 컨벤션 슬롯 채움. 부재 시 fallback (`rules.md` §reference 로드 모델).
2. **단계 식별** — 인자 또는 자유 텍스트로 어느 단계인지 결정. 모호하면 사용자에게 확인.
3. **단계별 절차 진행** — 각 단계의 본질·강제·산출은 `rules.md` 에 명시. 단계 간 인계 (다음 단계 안내) 는 SKILL 이 자동.
4. **(선택) `code-review` SKILL 인계** — refactor-layered 끝나면 사후 검토 단계로 이어짐.

자세한 4단계 본질·4계층 책임표·grep 위반 검출·TDD 사이클은 [`rules.md`](rules.md). 운영 체크리스트는 [`checklist.md`](checklist.md). 실제 사용 sample 은 [`examples/`](examples/).

원본 합성: [[wiki-03-backend-rules-pattern]] 의 *공용 골격 5요소* 그대로 입주 — NEXUS 슬롯은 reference 로드로 분리.

## 보안 고려사항

- `allow_commands` 필요 X — read 만 (사용처 reference + 기존 코드 / 테스트 / API 문서 읽기). 코드 수정·테스트 실행은 사용자 손 (또는 별 SKILL — `tdd-cycle` 의 Green 단계가 사용자에게 작성 지시).
- 동적 입력 (도메인 slug / 라우터명 / 파일 경로) 처리: `printf %q` 또는 quoted expansion (`"$VAR"`). `../` 탈출 / 절대 경로 / 심볼릭 검증.
- 시크릿 차단 + 출력 마스킹 — 아래 패턴은 read 대상에서 제외하고, 출력에 잡히면 `***` 으로 마스킹.

| 카테고리 | 경로/이름 패턴 | 정규식 (예) |
|----------|----------------|-------------|
| dotenv | `.env`, `.env.*` (`.local`, `.production` 등) | `(^|/)\.env(\..+)?$` |
| 시크릿 디렉토리 | `secrets/`, `secret/`, `credentials/` | `(^|/)(secrets?|credentials)/` |
| 토큰 파일 | `*token*`, `*apikey*`, `*api_key*` | `(token|api[_-]?key)` (대소문자 무시) |
| 키 자료 | `*.pem`, `*.key`, `*.p12`, `*.pfx`, `id_rsa*` | `\.(pem|key|p12|pfx)$\|^id_rsa` |
| 인증 헤더값 | `Authorization: Bearer ...`, `x-api-key: ...` | `(Bearer\s+\S+|x-api-key:\s*\S+)` |

- 위 패턴 매치 시: 입력 거부 (read 단계) + 출력 발견 시 `***` 치환. 사용처 환경별 추가 패턴은 본 § 에 보강.
