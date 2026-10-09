#!/usr/bin/env python3
"""Print the official Claude Code changelog entries for versions in (FROM, TO].

usage: changelog.py FROM TO        # e.g. changelog.py 2.1.285 2.1.286
       changelog.py --since-briefed TO

--since-briefed reads FROM from ~/.claude/.update-briefing.json, so an update
run outside the skill (plain `claude update` in a shell) still gets briefed.
Record a finished briefing with: changelog.py --mark-briefed TO
"""
import json, os, re, sys, urllib.request

URL = "https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md"
STATE = os.path.expanduser("~/.claude/.update-briefing.json")


def ver(s):
    return tuple(int(p) for p in s.split("."))


def main():
    args = sys.argv[1:]
    if len(args) == 2 and args[0] == "--mark-briefed":
        json.dump({"last_briefed": args[1]}, open(STATE, "w"))
        print(f"marked {args[1]} as briefed")
        return
    if len(args) == 2 and args[0] == "--since-briefed":
        try:
            frm = json.load(open(STATE))["last_briefed"]
        except (OSError, KeyError, ValueError):
            sys.exit("no briefing state yet; pass FROM explicitly")
        to = args[1]
    elif len(args) == 2:
        frm, to = args
    else:
        sys.exit(__doc__)

    if ver(frm) >= ver(to):
        print(f"nothing to brief: {frm} -> {to}")
        return

    text = urllib.request.urlopen(URL, timeout=20).read().decode()
    # Split on "## X.Y.Z" headings; keep sections in (frm, to].
    parts = re.split(r"^## (\d+\.\d+\.\d+)\s*$", text, flags=re.M)
    found = []
    for i in range(1, len(parts) - 1, 2):
        v, body = parts[i], parts[i + 1]
        if ver(frm) < ver(v) <= ver(to):
            found.append(v)
            print(f"## {v}\n{body.strip()}\n")
    if not found:
        # Changelog can lag the npm release by hours. Say so instead of
        # implying the release changed nothing.
        print(f"NO CHANGELOG ENTRIES for {frm} -> {to} yet (changelog may lag the release)")
    elif to not in found:
        print(f"WARNING: no entry for {to} itself yet; briefing is partial")


if __name__ == "__main__":
    main()
