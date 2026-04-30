# Example: 시나리오 1 — 상태 확인

> 사용자가 "내 mediness 설치 상태 보여줘" / 의도 모호한 경우 default 분기.

## 트리거

- "내 설치 어떻게 돼있어?"
- "mediness 깔려있나?"
- "역할 뭐로 셋업됐는지"
- (의도 모호 → fallback)

## 동작

### 1. plugin 목록 조회

```
$ claude plugin list
medi-base       0.1.0  (모든 role 의 의존)
medi-backend    0.1.0
```

### 2. settings 요약

```
~/.claude/settings.json:
- model: claude-sonnet-4-6
- permissions: 12개 박힘
- hooks: PostToolUse 1개 (docs-validate)
```

### 3. medi_docs 존재 여부

```
✓ medi_docs/current/ 존재 (9 카테고리 박힘)
✗ medi_docs/archive/ 미생성 (정상 — 첫 release 안 했음)
```

## 출력 포맷

```markdown
## Mediness 상태

**설치된 plugin** (2개)
- `medi-base@0.1.0` — 공통 자산
- `medi-backend@0.1.0` — 백엔드 role

**역할**: backend (단일)

**medi_docs**: 9 카테고리 scaffold 박힘 (cwd: `~/projects/foo`)

**다음 단계 후보**:
- 다른 role 추가 → "풀스택이라 frontend 도 추가" 같은 요청
- 첫 release → `archive/v0.1.0/` 박기 (현재 미생성)
```

## 보안 체크

- `claude plugin list` = read-only, 위험 X.
- `~/.claude/settings.json` 읽기만 (수정 X).
- 시크릿 token 노출 금지 — 출력에 `***` 마스킹.
