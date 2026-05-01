#!/usr/bin/env python3
"""Validate idea + spec frontmatters and regenerate docs/_map.md.

Each doc declares typed relationships:
  - sources       : spec absorbed which ideas (spec-only, M->1 lineage)
  - related_to    : soft cross-reference (any direction; deduped in _map)
  - supersedes    : this doc replaces another (DAG)
  - depends_on    : this doc depends on another (DAG)

Required frontmatter:
  - idea: id, type
  - spec: id, title, type, status, created, updated, sources, owns, tags
  - adr:  id, title, type, status, date, sources, tags

sources kind: spec.sources -> idea-*, adr.sources -> spec-*.
All relationship link targets must resolve to an existing doc.
supersedes and depends_on must be acyclic.

On success regenerates docs/_map.md (Relations / Specs / Ideas sections).
On violations: prints to stderr, exits 1, leaves _map.md untouched.
"""
import re
import sys
from pathlib import Path

SPEC_REQUIRED = ["id", "title", "type", "status", "created",
                 "updated", "sources", "owns", "tags"]
IDEA_REQUIRED = ["id", "type"]
ADR_REQUIRED = ["id", "title", "type", "status", "date", "sources", "tags"]
REL_FIELDS = ["related_to", "supersedes", "depends_on"]
LINK_FIELDS = ["sources"] + REL_FIELDS
BODY_LENGTH_LIMIT = 5000

# R10 role enum (content/adr only — meta-ADR 에는 N/A).
# ADR-0011 §1 정의 + ADR-0004 Notes 2026-04-30. 선택 필드 — 미박힘 통과, 박혔는데 enum 외면 차단.
ROLE_ALLOWED = ["base", "planner", "pm", "frontend", "backend", "qa", "infra"]

# adr.sources -> spec, spec.sources -> idea
SOURCE_PREFIX = {"spec": "idea-", "adr": "spec-"}

# status enum per kind. idea/콘텐츠 단계 status 는 *선택*; spec/adr 는 *필수*.
# adr 는 메타·콘텐츠 공통 (ADR-0004 R9, ADR-0003 §status 라이프사이클).
STATUS_ALLOWED = {
    "idea": ["open", "absorbed", "archived", "superseded", "rejected"],
    "spec": ["draft", "active", "accepted", "deprecated"],
    "adr": ["proposed", "accepted", "superseded", "deprecated"],
    "inbox": ["pending", "promoted", "archived"],
    "sources": ["pending", "promoted", "superseded"],
    "wiki": ["pending", "promoted", "superseded"],
    "harness": ["pending", "released"],
}


def parse_frontmatter(text):
    if not text.startswith("---\n"):
        return None
    end = text.find("\n---", 4)
    if end < 0:
        return None
    lines = text[4:end].splitlines()
    fm = {}
    i = 0
    while i < len(lines):
        m = re.match(r"^(\w+):\s*(.*)$", lines[i])
        if not m:
            i += 1
            continue
        key, val = m.group(1), m.group(2).strip()
        if val == "":
            items = []
            while i + 1 < len(lines) and re.match(r"^\s+-\s+", lines[i + 1]):
                item = re.sub(r"^\s+-\s+", "", lines[i + 1]).strip()
                item = re.sub(r'^"|"$', "", item)
                items.append(item)
                i += 1
            fm[key] = items
        elif val.startswith("[") and val.endswith("]"):
            inner = val[1:-1]
            fm[key] = [
                re.sub(r'^"|"$', "", x.strip())
                for x in inner.split(",")
                if x.strip()
            ]
        else:
            fm[key] = re.sub(r'^"|"$', "", val)
        i += 1
    return fm


def collect_docs(spec_dir, idea_dir, adr_dir):
    """Return {stem: (kind, path, fm)} and accumulated violations."""
    docs = {}
    violations = []
    for kind, d, required in (
        ("spec", spec_dir, SPEC_REQUIRED),
        ("idea", idea_dir, IDEA_REQUIRED),
        ("adr", adr_dir, ADR_REQUIRED),
    ):
        if not d.exists():
            continue
        for f in sorted(d.glob(f"{kind}-*.md")):
            rel = f"docs/{kind}/{f.name}"
            fm = parse_frontmatter(f.read_text())
            if fm is None:
                violations.append(f"[no-frontmatter] {rel}")
                continue
            missing = [k for k in required if k not in fm]
            if missing:
                violations.append(f"[missing-frontmatter] {rel}: {missing}")
            ftype = fm.get("type")
            if ftype and ftype != kind:
                violations.append(
                    f"[type-mismatch] {rel}: type={ftype!r} expected {kind!r}"
                )
            docs[f.stem] = (kind, f, fm)
    return docs, violations


def check_uniqueness(docs):
    out = []
    seen_id, seen_owns = {}, {}
    for stem, (kind, _, fm) in docs.items():
        v = fm.get("id")
        if v:
            if v in seen_id:
                out.append(f"[dup-id] '{v}': {seen_id[v]} vs {stem}")
            else:
                seen_id[v] = stem
        if kind == "spec":
            v = fm.get("owns")
            if v:
                if v in seen_owns:
                    out.append(f"[dup-owns] '{v}': {seen_owns[v]} vs {stem}")
                else:
                    seen_owns[v] = stem
    return out


def check_sources_required(docs):
    """spec.sources -> idea-*, adr.sources -> spec-*. Both non-empty."""
    out = []
    for stem, (kind, _, fm) in docs.items():
        if kind not in SOURCE_PREFIX:
            continue
        srcs = fm.get("sources")
        if not isinstance(srcs, list) or not srcs:
            out.append(f"[no-sources] {stem}: sources must be a non-empty list")
            continue
        expected = SOURCE_PREFIX[kind]
        for s in srcs:
            m = re.match(r"\[\[([^\]]+)\]\]", str(s))
            if m and not m.group(1).startswith(expected):
                out.append(
                    f"[bad-source-kind] {stem}: source must start with "
                    f"{expected!r}, got {m.group(1)}"
                )
    return out


def check_links(docs):
    """Every wikilink in any link field must resolve to a known doc."""
    out = []
    for stem, (_, _, fm) in docs.items():
        for field in LINK_FIELDS:
            v = fm.get(field)
            if not isinstance(v, list):
                continue
            for item in v:
                m = re.match(r"\[\[([^\]]+)\]\]", str(item))
                if not m:
                    out.append(f"[bad-link] {stem}.{field}: {item!r}")
                    continue
                target = m.group(1)
                if target == stem:
                    out.append(f"[self-link] {stem}.{field}: links to self")
                elif target not in docs:
                    out.append(f"[missing-target] {stem}.{field} -> {target}")
    return out


def extract_scope(path):
    """Pull first non-empty paragraph after `## Scope` heading. Returns '' if absent."""
    text = path.read_text()
    m = re.search(r"(?m)^##\s+Scope\s*\n+(.+?)(?=\n##\s|\Z)", text, re.S)
    if not m:
        return ""
    para = m.group(1).strip()
    # collapse whitespace, take first non-empty line
    for line in para.splitlines():
        s = line.strip()
        if s and not s.startswith("<!--"):
            return s
    return ""


def check_status_enum(docs):
    """Validate status field if present. Missing on spec/adr caught elsewhere."""
    out = []
    for stem, (kind, _, fm) in docs.items():
        status = fm.get("status")
        if status is None:
            continue
        allowed = STATUS_ALLOWED.get(kind, [])
        if status not in allowed:
            out.append(
                f"[bad-status] {stem}: status={status!r} not in {allowed}"
            )
    return out


def check_skill_layout(root):
    """R11: SKILL 디렉토리 표준 자산 존재 검증 (S5/S6/S7).

    스캔 대상:
      - .claude/skills/*/                                 (메인테이너 스킬)
      - content/harness/plugins/*/skills/*/                (사용자 배포본 — flat)
      - content/harness/plugins/*/skills/<role>/*/         (사용자 배포본 — role 분리)

    SKILL 디렉토리 = `SKILL.md` 보유 디렉토리. 발견 시 다음 검증:
      - S5: `examples/` 디렉토리 + 1+ non-hidden 자산
      - S6: `checklist.md` 파일 존재
      - S7: `rules.md` 파일 존재

    ADR-0007 §1 + Notes 2026-04-30. 메인테이너·사용자 영역 동일 룰.
    """
    out = []
    skill_roots = []
    maint = root / ".claude" / "skills"
    if maint.exists():
        skill_roots.append(maint)
    plugins = root / "content" / "harness" / "plugins"
    if plugins.exists():
        for p in plugins.iterdir():
            if not p.is_dir() or p.name.startswith("."):
                continue
            sk = p / "skills"
            if sk.exists():
                skill_roots.append(sk)

    skill_dirs = []
    for sr in skill_roots:
        # 1단 (skills/<name>/SKILL.md) 또는 2단 (skills/<role>/<name>/SKILL.md)
        for child in sr.iterdir():
            if not child.is_dir() or child.name.startswith("."):
                continue
            if (child / "SKILL.md").exists():
                skill_dirs.append(child)
                continue
            for grand in child.iterdir():
                if not grand.is_dir() or grand.name.startswith("."):
                    continue
                if (grand / "SKILL.md").exists():
                    skill_dirs.append(grand)

    for sk in skill_dirs:
        rel = sk.relative_to(root)
        ex = sk / "examples"
        if not ex.exists() or not ex.is_dir():
            out.append(f"[missing-skill-asset] {rel}: examples/ 디렉토리 누락 (S5)")
        else:
            assets = [c for c in ex.iterdir() if not c.name.startswith(".")]
            if not assets:
                out.append(f"[missing-skill-asset] {rel}: examples/ 비어있음 (S5)")
        if not (sk / "checklist.md").exists():
            out.append(f"[missing-skill-asset] {rel}: checklist.md 누락 (S6)")
        if not (sk / "rules.md").exists():
            out.append(f"[missing-skill-asset] {rel}: rules.md 누락 (S7)")
    return out


def check_wiki_sources_name_count(root):
    """R13: wiki 의 sources 로부터 *각자 SKILL 정체* 인 inbox 파일 카운트 정합 검증.

    promote-docs/rules.md §sources → wiki §N→1 합성의 한계:
      - sources 가 인용한 inbox 파일 중 frontmatter `name:` 보유 파일 카운트 = N
      - N > 1 인데 wiki 가 *1* 만 박혀 있으면 → 메타-내러티브로 잘못 묶음 가능성
      - violation: "wiki-XX 가 N 개의 자체 SKILL 을 묶음 — N wiki split 검토"

    sources 본문의 raw 인용 영역에서 `name:` 패턴 카운트. inbox 디렉토리 자산이
    아니면 (1 file 이면) skip. 메타-내러티브로 묶을 *정당* 한 케이스 (사용자
    합의) 는 wiki frontmatter `aliases:` 에 명시 사유 박으면 통과.
    """
    import re as _re

    out = []
    sources_dir = root / "content" / "sources"
    wiki_dir = root / "content" / "wiki"
    if not sources_dir.is_dir() or not wiki_dir.is_dir():
        return out

    # sources_id → name: count
    sources_name_counts = {}
    for src_file in sorted(sources_dir.glob("sources-*.md")):
        text = src_file.read_text()
        # raw 인용 영역에서 `name:` 카운트 — sources 본문의 frontmatter 가 아닌
        # 인용된 inbox 파일들의 frontmatter. 인용 영역은 fence 안 → "name: " 시작 라인
        # frontmatter 가 ~~~markdown 안에 있으므로 line-start ^name: 로 잡힘.
        # 다만 sources 자체 frontmatter 의 name: 도 있을 수 있으므로 frontmatter 후
        # 본문만 검사.
        if text.startswith("---\n"):
            end = text.find("\n---", 4)
            body = text[end + 4:] if end >= 0 else text
        else:
            body = text
        # raw 인용된 frontmatter 의 name: 라인 카운트
        n = len(_re.findall(r"^name:\s*\S+", body, _re.MULTILINE))
        sources_name_counts[src_file.stem] = n

    # sources 별 검사: name 카운트 N>1 인 sources 를 *N 이상의 wiki* 가 가리켜야 OK.
    # W < N 이면 under-split (합성자가 메타-내러티브로 묶음 가능성).
    wiki_count_by_source = {}
    wiki_alias_overrides = set()
    for wiki_file in sorted(wiki_dir.glob("wiki-*.md")):
        if wiki_file.name == "_map.md":
            continue
        fm = parse_frontmatter(wiki_file.read_text())
        if not fm:
            continue
        srcs = fm.get("sources", []) or []
        # 이 wiki 가 alias 로 override 박았는가
        aliases = fm.get("aliases", []) or []
        has_override = any(
            "split-skill" in str(a) or "merge-justified" in str(a)
            for a in aliases
        )
        for src in srcs:
            m = _re.match(r"\[\[([^\]]+)\]\]", str(src))
            if m:
                stem = m.group(1)
                wiki_count_by_source[stem] = wiki_count_by_source.get(stem, 0) + 1
                if has_override:
                    wiki_alias_overrides.add(stem)

    for src_stem, n_named in sources_name_counts.items():
        if n_named <= 1:
            continue
        n_wiki = wiki_count_by_source.get(src_stem, 0)
        if src_stem in wiki_alias_overrides:
            continue
        if n_wiki < n_named:
            out.append(
                f"[sources-under-split] content/sources/{src_stem}.md: "
                f"{n_named} 개의 자체 SKILL (`name:` frontmatter) 을 인용하지만 "
                f"{n_wiki} 개 wiki 만 가리킴 — *under-split* 가능성 (메타-내러티브로 묶음). "
                f"N wiki split 권장 (promote-docs/rules.md §sources→wiki §N→1 한계). "
                f"정당한 merge 면 해당 wiki 의 frontmatter `aliases: [merge-justified-<reason>]` 박을 것"
            )
    return out


def check_role_manifests(root):
    """R12: role-templates/<role>/role.json 의 skills/commands/hooks 배열이
    실재 디렉토리·파일과 일치하는지 검증.

    검증 대상: `content/harness/plugins/base/role-templates/<role>/role.json`

    검출:
      - manifest 가 선언한 skill 이 디렉토리로 실재 안 함        → violation (차단)
      - 디렉토리에 skill 이 있는데 manifest 에 없음 (orphan)     → violation
      - manifest JSON 파싱 실패                                   → violation
      - manifest 의 role 필드와 디렉토리 이름 불일치              → violation

    fallback (manifest 부재) 은 통과 — 마이그레이션 호환. 단, 메인테이너에게
    sync-role-manifest.sh 로 manifest 박을 것을 안내 (warning 으로 격하 가능).

    sync-role-manifest.sh 가 자동 갱신 도구 — 본 R12 가 drift 검출, sync 가
    drift 해소.
    """
    import json as _json

    out = []
    plugin_root = root / "content" / "harness" / "plugins" / "base"
    role_templates = plugin_root / "role-templates"
    if not role_templates.is_dir():
        return out

    for role_dir in sorted(role_templates.iterdir()):
        if not role_dir.is_dir() or role_dir.name.startswith("."):
            continue
        role_name = role_dir.name
        manifest_path = role_dir / "role.json"

        # filesystem state — skills/ 의 디렉토리 자식만 (.gitkeep 같은 파일은 skill 아님)
        fs_skills = sorted(
            [p.name for p in (role_dir / "skills").iterdir()
             if p.is_dir() and not p.name.startswith(".")]
            if (role_dir / "skills").is_dir()
            else []
        )
        fs_commands = sorted(
            [p.stem for p in (role_dir / "commands").glob("*.md")]
            if (role_dir / "commands").is_dir()
            else []
        )

        if not manifest_path.exists():
            # fallback OK, but flag for visibility (warning-grade — keep as
            # violation-tier 'note' to surface but not block; opted: warn-only)
            # 메인테이너 안내용 — 차단 X
            continue

        try:
            data = _json.loads(manifest_path.read_text())
        except _json.JSONDecodeError as e:
            out.append(f"[role-manifest-parse] {manifest_path.relative_to(root)}: {e}")
            continue

        # role 필드 일치
        m_role = data.get("role")
        if m_role != role_name:
            out.append(
                f"[role-manifest-name] {manifest_path.relative_to(root)}: "
                f"role={m_role!r} != dir name {role_name!r}"
            )

        # skills 배열 ↔ skills/ 디렉토리
        m_skills = data.get("skills", []) or []
        missing = [s for s in m_skills if s not in fs_skills]
        orphan = [s for s in fs_skills if s not in m_skills]
        for s in missing:
            out.append(
                f"[role-manifest-skill-missing] {manifest_path.relative_to(root)}: "
                f"skills[]={s!r} 선언했으나 skills/{s}/ 디렉토리 없음"
            )
        for s in orphan:
            out.append(
                f"[role-manifest-skill-orphan] {manifest_path.relative_to(root)}: "
                f"skills/{s}/ 디렉토리 있으나 manifest 에 없음 — sync-role-manifest.sh {role_name}"
            )

        # commands 배열 ↔ commands/*.md
        m_commands = data.get("commands", []) or []
        c_missing = [c for c in m_commands if c not in fs_commands]
        c_orphan = [c for c in fs_commands if c not in m_commands]
        for c in c_missing:
            out.append(
                f"[role-manifest-command-missing] {manifest_path.relative_to(root)}: "
                f"commands[]={c!r} 선언했으나 commands/{c}.md 없음"
            )
        for c in c_orphan:
            out.append(
                f"[role-manifest-command-orphan] {manifest_path.relative_to(root)}: "
                f"commands/{c}.md 있으나 manifest 에 없음"
            )

    return out


def check_content_adr_role(root):
    """R10: content/adr/*.md 의 role 필드 enum 검증.

    선택 필드 — 미박힘은 통과 (operator 가 빠뜨려도 차단 안 함). 박혔는데
    enum 외 값이면 차단. 메타 ADR (`docs/adr/`) 에는 N/A — content layer 만.
    ADR-0011 §1 + ADR-0004 Notes 2026-04-30.
    """
    out = []
    adr_dir = root / "content" / "adr"
    if not adr_dir.exists():
        return out
    for f in sorted(adr_dir.glob("adr-*.md")):
        fm = parse_frontmatter(f.read_text())
        if not fm:
            continue
        role = fm.get("role")
        if role is None:
            continue
        if role not in ROLE_ALLOWED:
            out.append(
                f"[bad-role] content/adr/{f.name}: role={role!r} "
                f"not in {ROLE_ALLOWED}"
            )
    return out


def check_body_length(docs):
    """Warn (not violate) when idea/spec body exceeds BODY_LENGTH_LIMIT chars.

    Body = file text minus frontmatter, stripped. Single-byte and multi-byte
    chars count equally (Python len on str).
    """
    warnings = []
    for stem, (kind, path, _) in docs.items():
        text = path.read_text()
        if text.startswith("---\n"):
            end = text.find("\n---", 4)
            body = text[end + 4:] if end >= 0 else text
        else:
            body = text
        n = len(body.strip())
        if n > BODY_LENGTH_LIMIT:
            warnings.append(
                f"[long-body] docs/{kind}/{path.name}: {n} chars "
                f"(limit {BODY_LENGTH_LIMIT})"
            )
    return warnings


def check_acyclic(docs, field):
    edges = {}
    for stem, (_, _, fm) in docs.items():
        targets = []
        for item in fm.get(field, []) or []:
            m = re.match(r"\[\[([^\]]+)\]\]", str(item))
            if m:
                targets.append(m.group(1))
        edges[stem] = targets

    out = []
    seen_cycles = set()
    WHITE, GRAY, BLACK = 0, 1, 2
    color = {n: WHITE for n in edges}

    def dfs(n, stack):
        color[n] = GRAY
        for t in edges.get(n, []):
            if t not in color:
                continue
            if color[t] == GRAY:
                cycle = stack[stack.index(t):] + [t]
                base = cycle[:-1]
                i = base.index(min(base))
                norm = tuple(base[i:] + base[:i])
                if norm not in seen_cycles:
                    seen_cycles.add(norm)
                    out.append(
                        f"[cycle-{field}] " + " -> ".join(list(norm) + [norm[0]])
                    )
            elif color[t] == WHITE:
                dfs(t, stack + [t])
        color[n] = BLACK

    for n in list(edges):
        if color[n] == WHITE:
            dfs(n, [n])
    return out


def link_md(stem, docs):
    if stem not in docs:
        return f"`{stem}` (missing)"
    sub = docs[stem][0]  # spec / idea / adr — directory matches kind
    return f"[{stem}]({sub}/{stem}.md)"


def regenerate_map(root, docs):
    map_path = root / "docs" / "_map.md"
    specs = {s: fm for s, (k, _, fm) in docs.items() if k == "spec"}
    ideas = {s: fm for s, (k, _, fm) in docs.items() if k == "idea"}
    adrs = {s: fm for s, (k, _, fm) in docs.items() if k == "adr"}

    # idea -> [spec] inverse
    inverse = {}
    spec_rows = []
    for stem, fm in sorted(specs.items(), key=lambda kv: kv[1].get("owns", "")):
        idea_stems = []
        for src in fm.get("sources", []):
            m = re.match(r"\[\[([^\]]+)\]\]", str(src))
            if m:
                idea_stems.append(m.group(1))
                inverse.setdefault(m.group(1), []).append(stem)
        sources_md = ", ".join(f"[{i}](idea/{i}.md)" for i in idea_stems) or "?"
        spec_path = next(p for s, (k, p, _) in docs.items() if s == stem)
        scope = extract_scope(spec_path) or "_(미작성)_"
        # escape pipe in scope to keep table valid
        scope_md = scope.replace("|", "\\|")
        spec_rows.append(
            f"| {fm.get('owns','?')} | {fm.get('status','?')} | "
            f"[{stem}](spec/{stem}.md) | {sources_md} | {scope_md} |"
        )

    idea_rows = []
    for stem in sorted(ideas):
        used_by = inverse.get(stem, [])
        if not used_by:
            used_by_md = "_(unpromoted)_"
        else:
            used_by_md = ", ".join(f"[{s}](spec/{s}.md)" for s in used_by)
            if len(used_by) > 1:
                used_by_md += "  ⚠ multi-spec"
        status = ideas[stem].get("status", "open")
        idea_rows.append(
            f"| [{stem}](idea/{stem}.md) | {status} | {used_by_md} |"
        )

    # spec -> [adr] inverse
    spec_inverse = {}
    adr_rows = []
    for stem, fm in sorted(adrs.items()):
        spec_stems = []
        for src in fm.get("sources", []):
            m = re.match(r"\[\[([^\]]+)\]\]", str(src))
            if m:
                spec_stems.append(m.group(1))
                spec_inverse.setdefault(m.group(1), []).append(stem)
        sources_md = ", ".join(f"[{s}](spec/{s}.md)" for s in spec_stems) or "?"
        adr_rows.append(
            f"| {fm.get('status','?')} | {fm.get('date','?')} | "
            f"[{stem}](adr/{stem}.md) | {sources_md} |"
        )

    n_unpromoted = sum(1 for s in ideas if s not in inverse)

    def collect(field):
        edges = []
        for stem, (_, _, fm) in docs.items():
            for item in fm.get(field, []) or []:
                m = re.match(r"\[\[([^\]]+)\]\]", str(item))
                if m:
                    edges.append((stem, m.group(1)))
        return edges

    sup_edges = sorted(collect("supersedes"))
    dep_edges = sorted(collect("depends_on"))
    rel_edges = collect("related_to")
    rel_dedup = sorted({tuple(sorted([a, b])) for a, b in rel_edges})

    lines = [
        "# Docs Map",
        "",
        "> 자동 생성. 수동 편집 금지. 재생성: `.claude/skills/docs-validate/scripts/validate.sh` (또는 docs/ 편집 시 자동 훅).",
        "",
        f"_{len(specs)} spec(s), {len(ideas)} idea(s), {len(adrs)} adr(s), "
        f"{n_unpromoted} unpromoted_",
        "",
        "## Relations",
        "",
        "### supersedes",
        "",
    ]
    if sup_edges:
        for a, b in sup_edges:
            lines.append(f"- {link_md(a, docs)} → {link_md(b, docs)}")
    else:
        lines.append("_(없음)_")
    lines += ["", "### depends_on", ""]
    if dep_edges:
        for a, b in dep_edges:
            lines.append(f"- {link_md(a, docs)} → {link_md(b, docs)}")
    else:
        lines.append("_(없음)_")
    lines += ["", "### related_to", ""]
    if rel_dedup:
        for a, b in rel_dedup:
            lines.append(f"- {link_md(a, docs)} ↔ {link_md(b, docs)}")
    else:
        lines.append("_(없음)_")

    lines += ["", "## Specs", ""]
    if spec_rows:
        lines += [
            "| Topic | Status | Spec | Sources | Scope |",
            "|-------|--------|------|---------|-------|",
        ] + spec_rows
    else:
        lines.append("_(없음)_")

    lines += ["", "## Ideas (lineage view)", ""]
    if idea_rows:
        lines += [
            "| File | Status | Absorbed into |",
            "|------|--------|---------------|",
        ] + idea_rows
    else:
        lines.append("_(없음)_")

    lines += ["", "## ADRs", ""]
    if adr_rows:
        lines += [
            "| Status | Date | ADR | Source spec |",
            "|--------|------|-----|-------------|",
        ] + adr_rows
    else:
        lines.append("_(없음)_")
    lines.append("")
    map_path.write_text("\n".join(lines))


def regenerate_content_map(root):
    """Minimal content/_map.md placeholder. ADR-0001 § 콘텐츠 레이어 인덱스.

    콘텐츠 단계 (inbox/sources/wiki/adr/harness) frontmatter 명세 미정 (ADR-0004
    line 130) — 자산별 풍부 인덱싱은 명세 박힌 후 보강. 현재는 단계별 자산 카운트만.
    """
    content_root = root / "content"
    if not content_root.exists():
        return  # 콘텐츠 레이어 미가동
    map_path = content_root / "_map.md"

    # 자산 단위 카운트 — ADR-0003 §자산 단위
    # - inbox        : 직접 자식 (파일 or 디렉토리) = 1 자산
    # - sources/wiki/adr : .md 1 file = 1 자산 (sources 평탄화 룰을 wiki/adr 도 승계)
    # - harness      : harness/plugins/<name>/ = 1 plugin = 1 자산
    #                  (.claude-plugin/marketplace.json 은 배포 metadata, 자산 아님)
    stages = ["inbox", "sources", "wiki", "adr", "harness"]
    counts = {}
    status_counts = {}  # stage -> {status: n}. ADR-0003 §status 라이프사이클.
    cat_counts = {}     # category -> n. ADR-0003 §categories.
    for stage in stages:
        d = content_root / stage
        status_counts[stage] = {}
        if not d.exists():
            counts[stage] = 0
            continue
        if stage == "inbox":
            counts[stage] = sum(
                1 for c in d.iterdir() if not c.name.startswith(".")
            )
            # inbox raw 는 frontmatter 미박 가능 — status/categories 인덱싱 skip
        elif stage == "harness":
            plugins_dir = d / "plugins"
            counts[stage] = (
                sum(
                    1
                    for c in plugins_dir.iterdir()
                    if c.is_dir() and not c.name.startswith(".")
                )
                if plugins_dir.exists()
                else 0
            )
            # harness plugin manifest status/categories 인덱싱은 v0.2 운영 후
        else:
            files = [f for f in d.rglob("*.md") if f.name != "_map.md"]
            counts[stage] = len(files)
            for f in files:
                fm = parse_frontmatter(f.read_text())
                if not fm:
                    continue
                if fm.get("status"):
                    s = fm["status"]
                    status_counts[stage][s] = status_counts[stage].get(s, 0) + 1
                cats = fm.get("categories")
                if isinstance(cats, list):
                    for c in cats:
                        cat_counts[c] = cat_counts.get(c, 0) + 1
    total = sum(counts.values())

    def fmt_stage(stage):
        c = counts[stage]
        if c == 0:
            return f"{stage} 0"
        sc = status_counts[stage]
        if sc:
            parts = ", ".join(f"{s}: {n}" for s, n in sorted(sc.items()))
            return f"{stage} {c} ({parts})"
        return f"{stage} {c}"

    lines = [
        "# Content Map",
        "",
        "> 자동 생성. 수동 편집 금지. 재생성: "
        "`.claude/skills/docs-validate/scripts/validate.sh`. ADR-0001 §콘텐츠 레이어 인덱스 "
        "(메타 `docs/_map.md` 와 평행).",
        "",
        f"_5단 자산: {fmt_stage('inbox')} · {fmt_stage('sources')} · "
        f"{fmt_stage('wiki')} · {fmt_stage('adr')} · {fmt_stage('harness')} "
        f"(총 {total})_",
        "",
    ]
    # categories facet (ADR-0003 §categories)
    if cat_counts:
        lines.append("## Categories")
        lines.append("")
        for cat, n in sorted(cat_counts.items(), key=lambda kv: (-kv[1], kv[0])):
            lines.append(f"- `{cat}` — {n}")
        lines.append("")
    lines += [
        "## Stages",
        "",
        "- `inbox/` — 모든 기여자 공용 입구. raw dump",
        "- `sources/` — 1차 가공 = 정체화 (이름·목적 박음, 이후 불변)",
        "- `wiki/` — 합성·정리 (LLM + 인간 검토)",
        "- `adr/` — atomic 결정 (자산-plugin 매핑)",
        "- `harness/` — 배포 (5단 마지막 = distribution monorepo)",
        "",
        "레거시 자산 (회사에 흩어진 SKILL/hook/MCP/settings) 은 `inbox/` PR 로 흘러들어옴 "
        "→ 메인테이너 triage ([[adr-0002-permissions-flow]] §inbox 워크플로우 §4) "
        "→ 콘텐츠 5단 또는 메타 3단 분기.",
        "",
        "_(자산별 풍부 인덱싱은 콘텐츠 단계 frontmatter 명세 박힌 후 보강 — "
        "ADR-0004 line 130)_",
        "",
    ]
    map_path.write_text("\n".join(lines))


def main(root):
    root = Path(root)
    spec_dir = root / "docs" / "spec"
    idea_dir = root / "docs" / "idea"
    adr_dir = root / "docs" / "adr"
    docs, violations = collect_docs(spec_dir, idea_dir, adr_dir)
    violations += check_uniqueness(docs)
    violations += check_sources_required(docs)
    violations += check_links(docs)
    violations += check_acyclic(docs, "supersedes")
    violations += check_acyclic(docs, "depends_on")
    violations += check_status_enum(docs)
    violations += check_content_adr_role(root)
    violations += check_skill_layout(root)
    violations += check_role_manifests(root)
    violations += check_wiki_sources_name_count(root)
    warnings = check_body_length(docs)

    if violations:
        print("VIOLATIONS:", file=sys.stderr)
        for v in violations:
            print(f"  - {v}", file=sys.stderr)
        print(
            f"\n{len(violations)} violation(s). _map.md NOT regenerated.",
            file=sys.stderr,
        )
        sys.exit(1)

    if warnings:
        print("WARNINGS:", file=sys.stderr)
        for w in warnings:
            print(f"  - {w}", file=sys.stderr)
        print(file=sys.stderr)

    regenerate_map(root, docs)
    regenerate_content_map(root)
    n_spec = sum(1 for k, _, _ in docs.values() if k == "spec")
    n_idea = sum(1 for k, _, _ in docs.values() if k == "idea")
    n_adr = sum(1 for k, _, _ in docs.values() if k == "adr")
    content_msg = (
        " content/_map.md regenerated."
        if (root / "content").exists()
        else ""
    )
    print(
        f"OK: {n_spec} spec(s), {n_idea} idea(s), {n_adr} adr(s) consistent. "
        f"docs/_map.md regenerated.{content_msg}"
    )


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else ".")
