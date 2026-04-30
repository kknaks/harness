#!/usr/bin/env python3
"""Sync role manifest (`role.json`) with the filesystem.

`role-templates/<role>/{skills,commands,hooks}/` 디렉토리를 스캔하여
`role-templates/<role>/role.json` 의 배열 (skills / commands / hooks) 을
실재 디렉토리·파일과 일치시킨다. role / version / description / depends_on
같은 *scalar* 필드는 보존 — 메인테이너가 손으로 둔 메타데이터는 안 건드림.

`role.json` 이 없으면 skeleton 생성 (description=TODO 박힘 → 메인테이너가
나중에 채움).

300+ SKILL 일괄 갱신 시 안전망 — 디렉토리만 mv/rm/cp 하면 manifest 가 따라옴.

Usage:
  sync-role-manifest.py <role>          # 단일 role
  sync-role-manifest.py --all           # role-templates/ 아래 전부

Exit codes:
  0 = 성공 (변경 0+)
  1 = role 인자 부족 또는 알 수 없는 role
  2 = role-templates/ 디렉토리 자체 부재 (plugin 구조 깨짐)
"""
import json
import sys
from pathlib import Path


def discover_plugin_root():
    """Find content/harness/plugins/base/ from this script's location.

    Script lives at .claude/skills/promote-docs/scripts/sync-role-manifest.py.
    Plugin root is content/harness/plugins/base/ at repo root.
    """
    script = Path(__file__).resolve()
    # Walk up from script to find repo root (looks for `.git` or `.claude`)
    for ancestor in script.parents:
        candidate = ancestor / "content" / "harness" / "plugins" / "base"
        if candidate.is_dir():
            return candidate
    print("plugin root (content/harness/plugins/base/) not found", file=sys.stderr)
    sys.exit(2)


def list_subdirs(parent):
    if not parent.is_dir():
        return []
    return sorted([p.name for p in parent.iterdir() if p.is_dir() and not p.name.startswith(".")])


def list_md_stems(parent):
    if not parent.is_dir():
        return []
    return sorted([p.stem for p in parent.glob("*.md") if not p.name.startswith(".")])


def sync_role(role_dir):
    """Sync the role.json in role_dir with filesystem. Returns (changed, summary)."""
    manifest_path = role_dir / "role.json"
    role_name = role_dir.name

    skills_present = list_subdirs(role_dir / "skills")
    commands_present = list_md_stems(role_dir / "commands")
    hooks_present = list_md_stems(role_dir / "hooks")  # adjust if hooks are dirs

    if manifest_path.exists():
        try:
            data = json.loads(manifest_path.read_text())
        except json.JSONDecodeError as e:
            return False, f"FAIL parse {manifest_path}: {e}"
        # Preserve scalar fields, only sync arrays
        existing = {
            "role": data.get("role", role_name),
            "version": data.get("version", "0.1.0"),
            "description": data.get("description", "TODO"),
            "depends_on": data.get("depends_on", []),
        }
    else:
        existing = {
            "role": role_name,
            "version": "0.1.0",
            "description": "TODO — fill description for /harness:status display",
            "depends_on": [],
        }
        data = {}

    new_data = {
        "role": existing["role"],
        "version": existing["version"],
        "description": existing["description"],
        "skills": skills_present,
        "commands": commands_present,
        "hooks": hooks_present,
        "depends_on": existing["depends_on"],
    }

    # Diff
    changes = []
    if not manifest_path.exists():
        changes.append("created (skeleton)")
    else:
        for k in ("skills", "commands", "hooks"):
            old = data.get(k, []) or []
            new = new_data[k]
            added = sorted(set(new) - set(old))
            removed = sorted(set(old) - set(new))
            if added:
                changes.append(f"{k} +{added}")
            if removed:
                changes.append(f"{k} -{removed}")

    if not changes:
        return False, f"OK {role_name}: in sync (skills={len(skills_present)}, commands={len(commands_present)}, hooks={len(hooks_present)})"

    manifest_path.write_text(json.dumps(new_data, ensure_ascii=False, indent=2) + "\n")
    return True, f"SYNC {role_name}: {' / '.join(changes)}"


def main():
    args = sys.argv[1:]
    if not args:
        print("Usage: sync-role-manifest.py <role>|--all", file=sys.stderr)
        sys.exit(1)

    plugin_root = discover_plugin_root()
    role_templates = plugin_root / "role-templates"
    if not role_templates.is_dir():
        print(f"role-templates/ not found under {plugin_root}", file=sys.stderr)
        sys.exit(2)

    if args[0] == "--all":
        roles = list_subdirs(role_templates)
        if not roles:
            print("No role directories under role-templates/", file=sys.stderr)
            sys.exit(0)
    else:
        target = args[0]
        if not (role_templates / target).is_dir():
            avail = list_subdirs(role_templates)
            print(f"Unknown role: {target}", file=sys.stderr)
            print(f"Available: {' '.join(avail)}", file=sys.stderr)
            sys.exit(1)
        roles = [target]

    n_changed = 0
    for role in roles:
        changed, summary = sync_role(role_templates / role)
        print(f"  {summary}")
        if changed:
            n_changed += 1

    if n_changed:
        print(f"\n{n_changed} manifest(s) updated. Run validate to cross-check.")
    else:
        print(f"\nAll {len(roles)} manifest(s) already in sync.")


if __name__ == "__main__":
    main()
