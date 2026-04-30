"""
Helper: bump frontmatter `status:` to a new value (or insert if absent).
Used inline by promote sh scripts. Idempotent if status already matches target.
"""
import sys, re, pathlib

def bump_status(path_str, new_status):
    p = pathlib.Path(path_str)
    text = p.read_text()
    if not text.startswith("---\n"):
        sys.stderr.write(f"[update-status] no frontmatter: {path_str}\n")
        return False
    end = text.find("\n---", 4)
    if end < 0:
        sys.stderr.write(f"[update-status] frontmatter unterminated: {path_str}\n")
        return False
    fm_block = text[4:end]
    rest = text[end:]

    if re.search(r'(?m)^status:\s*' + re.escape(new_status) + r'\s*$', fm_block):
        return True  # idempotent

    if re.search(r'(?m)^status:\s*\S', fm_block):
        fm_block = re.sub(r'(?m)^status:.*$', f'status: {new_status}', fm_block, count=1)
    else:
        # insert after `type:` line if exists, else at top
        m = re.search(r'(?m)^type:.*$', fm_block)
        if m:
            insert_at = m.end()
            fm_block = fm_block[:insert_at] + f"\nstatus: {new_status}" + fm_block[insert_at:]
        else:
            fm_block = f"status: {new_status}\n" + fm_block

    p.write_text("---\n" + fm_block + rest)
    return True

if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.stderr.write("usage: update-status.py <file> <new-status>\n")
        sys.exit(2)
    ok = bump_status(sys.argv[1], sys.argv[2])
    sys.exit(0 if ok else 1)
