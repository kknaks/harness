---
name: harness
description: mediness plugin 셋업·역할 변경·동기화·정리 단일 진입점 (사용자용 onboarding)
allowed_tools: [Read, Edit, Bash]
allow_commands:
  - "claude plugin install"
  - "claude plugin uninstall"
  - "claude plugin list"
  - "git config"
reads_files:
  - "[[~/.claude/settings.json]]"
  - "[[base/plugin.json]]"
runs_scripts:
  - "[[scripts/scaffold-medi-docs.sh]]"
env_vars:
  - HARNESS_GITHUB_TOKEN
---

# Harness — Mediness Onboarding

mediness plugin 의 **단일 사용자 진입점**. Claude 가 현재 설치 상태 + 사용자 의도를 보고 6 시나리오 분기. sub-command 분할 X — 한 명령만 기억 (ADR-0006).

## When to use

- 처음 mediness plugin install 후 셋업 시작
- 역할 변경 (예: 백엔드 → 인프라) 또는 다중 역할 (풀스택)
- 회사 CLAUDE.md / 공통 settings 갱신
- 정리·재설치
- 현재 설치 상태 확인

## What it does

1. **상태 확인 우선** — `claude plugin list` 로 현재 설치된 plugin·역할 보고
2. **의도 파악** — 사용자 응답 + 상태 보고 → 6 시나리오 분기
3. **dry-run** — 무엇을 할지 사용자에 확인 후 동의 시 실행
4. **idempotent** — 부분 설치 상태에서 재호출해도 안전
5. **medi_docs scaffold** — 처음 셋업 시 `scripts/scaffold-medi-docs.sh` 호출 → 사용자 cwd 의 `medi_docs/current/` 9 카테고리 scaffold (ADR-0008 §4). 이미 존재 시 no-op

v0.1 = **상태 확인 시나리오 우선**. 처음 셋업 / 역할 변경 / 다중 역할 시나리오는 v0.1 release 전 보강. 환경 동기화 / 정리·재설치는 v0.2.

## 보안 고려사항

- `allow_commands` 위험 명령: `claude plugin install/uninstall` (사용자 환경 변경), `git config` (사용자 git 설정) — 모두 dry-run 동의 후 실행.
- `~/.claude/settings.json` 읽기/수정 시 백업 권장.
- 시크릿 (`HARNESS_GITHUB_TOKEN` 등) 은 셸 rc / OS keychain 보관 — harness skill 자체는 token 저장·관리 X (ADR-0010 §3).
- LLM 분기 실패 시 *상태 확인* fallback 자연 — idempotent + dry-run 으로 잘못된 install/uninstall 위험 0.
