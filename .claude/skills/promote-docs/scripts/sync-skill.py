#!/usr/bin/env python3
"""Sync `create-skill.sh` 보편 슬롯 갱신을 기존 SKILL 디렉토리에 적용.

대상: SKILL.md `## 보안 고려사항` § (시크릿 마스킹 표) + rules.md / checklist.md
의 SSOT 분리 docstring (rules = 본질, checklist = 운영). idempotent + additive —
마커 문자열로 already-synced 판정, 변경분만 적용.

조건부 슬롯 (reference 로드 모델, phase 표 헤더, 산출 포맷 이슈 ID scope) 은
*다루지 않음* — `.claude/skills/promote-docs/rules.md` §"Skill / Wiki 합성 시
조건부 슬롯 체크리스트" 가 합성자 책임 영역.

Usage:
  sync-skill.py <skill-dir>            # dry-run, prints diff
  sync-skill.py <skill-dir> --apply    # writes changes

Exit codes:
  0 = no-op (already synced) 또는 apply 성공
  1 = 변경 필요 (dry-run, --apply 없이)
  2 = 인자/경로 오류
"""
import re
import sys
from pathlib import Path

# 보안 § 본문 (SKILL.md). create-skill.sh heredoc 의 § 와 동일.
SECURITY_BLOCK = """## 보안 고려사항

- `allow_commands` 선언 이유: (위험 명령 호출 시 — 없으면 "X — read/write only")
- 동적 입력 ($VAR / CLI 인자 / 파일 경로) 처리: `source ../scripts/sanitize.sh` 또는 인용 규칙 (`"$VAR"`/`printf %q`).
- 시크릿 차단 + 출력 마스킹 — 아래 패턴은 read 대상에서 제외하고, 출력에 잡히면 `***` 으로 마스킹.

| 카테고리 | 경로/이름 패턴 | 정규식 (예) |
|----------|----------------|-------------|
| dotenv | `.env`, `.env.*` (`.local`, `.production` 등) | `(^|/)\\.env(\\..+)?$` |
| 시크릿 디렉토리 | `secrets/`, `secret/`, `credentials/` | `(^|/)(secrets?|credentials)/` |
| 토큰 파일 | `*token*`, `*apikey*`, `*api_key*` | `(token|api[_-]?key)` (대소문자 무시) |
| 키 자료 | `*.pem`, `*.key`, `*.p12`, `*.pfx`, `id_rsa*` | `\\.(pem|key|p12|pfx)$\\|^id_rsa` |
| 인증 헤더값 | `Authorization: Bearer ...`, `x-api-key: ...` | `(Bearer\\s+\\S+|x-api-key:\\s*\\S+)` |

- 위 패턴 매치 시: 입력 거부 (read 단계) + 출력 발견 시 `***` 치환. 사용처 환경별 추가 패턴은 본 § 에 보강.
"""

# rules.md docstring. SKILL trigger / SSOT 분리 두 줄. 기존 1줄 blockquote 가
# 있다면 그 자리를 통째 대체 (legacy → enriched). H1 직후가 정상 위치.
RULES_BLOCKQUOTE = """> 스킬이 강제하는 룰셋·정책·금지 사항. SKILL.md (사용자 시점 진입점) 가 trigger 시 로드 → 본 rules.md 는 실제 룰 적용 시점에 지연 로드 ([[adr-0007-skill-authoring-rules]] §1).
>
> **rules.md 의 책임 (본질·SSOT)**: *무엇을 강제하는가 / 왜 / 위반 시 어떻게 되는가*. 도메인 룰 본문·정책·금지·예외 처리. 운영 단계 (Pre-flight / Action / Post-flight 표) 는 `checklist.md` 가 SSOT — rules 에는 박지 않음 ([[adr-0007-skill-authoring-rules]] §1 SKILL.md vs rules.md vs checklist.md 분리). 같은 정보가 양쪽에 박히면 표류 — 한쪽만 SSOT.
"""

# checklist.md docstring. H1 직후 삽입 (기존 blockquote 없을 가능성 높음 —
# 기존 scaffold 가 박지 않았음).
CHECKLIST_BLOCKQUOTE = """> 운영 체크리스트 — *어떤 순서로 무엇을 점검·실행·검증하는가* (SSOT).
> 룰의 본질 (왜 강제되는가) 은 `rules.md` 가 SSOT. 본 checklist 는 *실행 절차* 만 — 룰 본문 중복 박지 않음.
> 운영 점검 항목이 늘어나면 본 파일을, 룰 자체가 늘어나면 `rules.md` 를 갱신.
"""

# already-synced detection 마커. 이 문자열이 발견되면 sync 가 변경 안 함.
SECURITY_MARKER = "시크릿 차단 + 출력 마스킹"
RULES_MARKER = "rules.md 의 책임 (본질·SSOT)"
CHECKLIST_MARKER = "운영 체크리스트 — *어떤 순서로"


def replace_section(text, heading, replacement):
    """Replace H2 § with given heading by `replacement`. Append at EOF if absent.

    `heading` = full heading line (e.g. "## 보안 고려사항"). Section ends at next
    H2 or EOF. `replacement` includes the heading.
    """
    pattern = re.compile(
        r"^" + re.escape(heading) + r"\s*\n", re.MULTILINE
    )
    m = pattern.search(text)
    if not m:
        sep = "" if text.endswith("\n") else "\n"
        suffix = "" if replacement.endswith("\n") else "\n"
        return text + sep + "\n" + replacement + suffix
    start = m.start()
    next_h2 = re.search(r"^##\s", text[m.end():], re.MULTILINE)
    if next_h2:
        end = m.end() + next_h2.start()
        return text[:start] + replacement + text[end:]
    return text[:start] + replacement


def insert_after_h1(text, blockquote):
    """Insert blockquote after H1. If existing blockquote follows H1, replace it.

    blockquote = full multiline blockquote ending with newline. Result:
        # H1
        \n
        > ...
        > ...
        \n
        rest...
    """
    h1 = re.search(r"^#\s+.+\n", text, re.MULTILINE)
    if not h1:
        return text  # No H1, leave alone
    after = h1.end()
    rest = text[after:]
    # consume leading blank lines
    blanks = re.match(r"\n*", rest).group(0)
    body = rest[len(blanks):]
    # if body starts with blockquote, consume it
    if body.startswith(">"):
        bq_lines = []
        for line in body.splitlines(keepends=True):
            if line.startswith(">"):
                bq_lines.append(line)
            else:
                break
        body = body[sum(len(l) for l in bq_lines):]
    # ensure body has a leading blank line for separation
    body_lstripped = body.lstrip("\n")
    return text[:after] + "\n" + blockquote + "\n" + body_lstripped


def sync_skill_md(path):
    text = path.read_text()
    if SECURITY_MARKER in text:
        return None  # already synced
    return replace_section(text, "## 보안 고려사항", SECURITY_BLOCK)


def sync_rules_md(path):
    text = path.read_text()
    if RULES_MARKER in text:
        return None
    return insert_after_h1(text, RULES_BLOCKQUOTE)


def sync_checklist_md(path):
    text = path.read_text()
    if CHECKLIST_MARKER in text:
        return None
    return insert_after_h1(text, CHECKLIST_BLOCKQUOTE)


def diff_summary(old, new, path):
    """Minimal contextual diff — prints +/- count + first 3 changed lines."""
    old_lines = old.splitlines()
    new_lines = new.splitlines()
    added = len(new_lines) - len(old_lines)
    sign = "+" if added >= 0 else ""
    return f"  {path}: net {sign}{added} lines (was {len(old_lines)}, now {len(new_lines)})"


def main():
    args = sys.argv[1:]
    apply = "--apply" in args
    args = [a for a in args if a != "--apply"]
    if not args:
        print(__doc__, file=sys.stderr)
        sys.exit(2)
    target = Path(args[0]).resolve()
    if not target.is_dir():
        print(f"not a directory: {target}", file=sys.stderr)
        sys.exit(2)
    if not (target / "SKILL.md").exists():
        print(f"not a SKILL directory (no SKILL.md): {target}", file=sys.stderr)
        sys.exit(2)

    handlers = [
        ("SKILL.md", sync_skill_md),
        ("rules.md", sync_rules_md),
        ("checklist.md", sync_checklist_md),
    ]

    changes = []
    for fname, fn in handlers:
        p = target / fname
        if not p.exists():
            continue  # missing rules.md/checklist.md is a separate violation
        new_text = fn(p)
        if new_text is None:
            continue
        old = p.read_text()
        changes.append((p, old, new_text))

    if not changes:
        print(f"OK: {target.relative_to(Path.cwd()) if target.is_relative_to(Path.cwd()) else target} 이미 sync 됨.")
        sys.exit(0)

    if apply:
        for p, _, new in changes:
            p.write_text(new)
        print(f"APPLIED: {len(changes)} file(s) updated in {target}")
        for p, old, new in changes:
            print(diff_summary(old, new, p.name))
        sys.exit(0)
    else:
        print(f"DRY-RUN: {len(changes)} file(s) need sync in {target}")
        for p, old, new in changes:
            print(diff_summary(old, new, p.name))
        print("\n--apply 로 실제 적용.")
        sys.exit(1)


if __name__ == "__main__":
    main()
