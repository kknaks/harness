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
REL_FIELDS = ["related_to", "supersedes", "depends_on"]
LINK_FIELDS = ["sources"] + REL_FIELDS


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


def collect_docs(spec_dir, idea_dir):
    """Return {stem: (kind, path, fm)} and accumulated violations."""
    docs = {}
    violations = []
    for kind, d, required in (
        ("spec", spec_dir, SPEC_REQUIRED),
        ("idea", idea_dir, IDEA_REQUIRED),
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
    """spec.sources non-empty list of wikilinks pointing at idea-* docs."""
    out = []
    for stem, (kind, _, fm) in docs.items():
        if kind != "spec":
            continue
        srcs = fm.get("sources")
        if not isinstance(srcs, list) or not srcs:
            out.append(f"[no-sources] {stem}: sources must be a non-empty list")
            continue
        for s in srcs:
            m = re.match(r"\[\[([^\]]+)\]\]", str(s))
            if m and not m.group(1).startswith("idea-"):
                out.append(
                    f"[bad-source-kind] {stem}: source must be an idea, got {m.group(1)}"
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
    sub = "spec" if docs[stem][0] == "spec" else "idea"
    return f"[{stem}]({sub}/{stem}.md)"


def regenerate_map(root, docs):
    map_path = root / "docs" / "_map.md"
    specs = {s: fm for s, (k, _, fm) in docs.items() if k == "spec"}
    ideas = {s: fm for s, (k, _, fm) in docs.items() if k == "idea"}

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
        spec_rows.append(
            f"| {fm.get('owns','?')} | {fm.get('status','?')} | "
            f"[{stem}](spec/{stem}.md) | {sources_md} |"
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
        idea_rows.append(f"| [{stem}](idea/{stem}.md) | {used_by_md} |")

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
        f"_{len(specs)} spec(s), {len(ideas)} idea(s), {n_unpromoted} unpromoted_",
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
            "| Topic | Status | Spec | Sources |",
            "|-------|--------|------|---------|",
        ] + spec_rows
    else:
        lines.append("_(없음)_")

    lines += ["", "## Ideas (lineage view)", ""]
    if idea_rows:
        lines += [
            "| File | Absorbed into |",
            "|------|---------------|",
        ] + idea_rows
    else:
        lines.append("_(없음)_")
    lines.append("")
    map_path.write_text("\n".join(lines))


def main(root):
    root = Path(root)
    spec_dir = root / "docs" / "spec"
    idea_dir = root / "docs" / "idea"
    docs, violations = collect_docs(spec_dir, idea_dir)
    violations += check_uniqueness(docs)
    violations += check_sources_required(docs)
    violations += check_links(docs)
    violations += check_acyclic(docs, "supersedes")
    violations += check_acyclic(docs, "depends_on")

    if violations:
        print("VIOLATIONS:", file=sys.stderr)
        for v in violations:
            print(f"  - {v}", file=sys.stderr)
        print(
            f"\n{len(violations)} violation(s). _map.md NOT regenerated.",
            file=sys.stderr,
        )
        sys.exit(1)

    regenerate_map(root, docs)
    n_spec = sum(1 for k, _, _ in docs.values() if k == "spec")
    n_idea = sum(1 for k, _, _ in docs.values() if k == "idea")
    print(
        f"OK: {n_spec} spec(s), {n_idea} idea(s) consistent. docs/_map.md regenerated."
    )


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else ".")
