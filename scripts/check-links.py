#!/usr/bin/env python3
"""Check that every relative link and image in the repository's Markdown
resolves to an existing file (and, for #anchors into Markdown, a heading).
External http(s) links are not fetched. Exit 1 on any broken link."""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LINK = re.compile(r'!?\[[^\]]*\]\(([^)\s]+)(?:\s+"[^"]*")?\)|<img[^>]+src="([^"]+)"|<a[^>]+href="([^"]+)"')
SKIP_DIRS = {".git", "node_modules", "result", "build", "bench-results"}

def anchors(path):
    out = set()
    with open(path, encoding="utf-8") as f:
        for line in f:
            m = re.match(r"^#{1,6}\s+(.*)", line)
            if m:
                slug = re.sub(r"[^\w\- ]", "", m.group(1).strip().lower()).replace(" ", "-")
                out.add(slug)
    return out

bad = 0
checked = 0
for dirpath, dirnames, files in os.walk(ROOT):
    dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
    for name in files:
        if not name.endswith(".md"):
            continue
        src = os.path.join(dirpath, name)
        text = open(src, encoding="utf-8").read()
        text = re.sub(r"```.*?```", "", text, flags=re.S)  # ignore code blocks
        for m in LINK.finditer(text):
            target = next(g for g in m.groups() if g)
            if re.match(r"^(https?:|mailto:|#$)", target):
                continue
            checked += 1
            path, _, frag = target.partition("#")
            full = os.path.normpath(os.path.join(dirpath, path)) if path else src
            rel = os.path.relpath(src, ROOT)
            if not os.path.exists(full):
                print(f"BROKEN  {rel}: {target}")
                bad += 1
            elif frag and full.endswith(".md") and frag not in anchors(full):
                print(f"ANCHOR  {rel}: {target}")
                bad += 1
print(f"checked {checked} internal links, {bad} broken")
sys.exit(1 if bad else 0)
