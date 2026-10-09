#!/usr/bin/env python3
"""Register (or remove) the auto-briefing SessionStart hook in ~/.claude/settings.json.

usage: install_hook.py            # add the hook (safe to re-run)
       install_hook.py --uninstall
"""
import json, os, shutil, sys

SETTINGS = os.path.expanduser("~/.claude/settings.json")
HOOK = os.path.join(os.path.dirname(os.path.abspath(__file__)), "autobrief.sh")
CMD = f'bash "{HOOK}"'


def ours(entry):
    return any(h.get("command", "").endswith('autobrief.sh"') for h in entry.get("hooks", []))


def main():
    uninstall = sys.argv[1:] == ["--uninstall"]
    if sys.argv[1:] and not uninstall:
        sys.exit(__doc__)
    try:
        settings = json.load(open(SETTINGS))
    except FileNotFoundError:
        settings = {}
    starts = settings.setdefault("hooks", {}).setdefault("SessionStart", [])
    kept = [e for e in starts if not ours(e)]
    if not uninstall:
        kept.append({"hooks": [{"type": "command", "command": CMD, "timeout": 10}]})
    if kept == starts:
        print("nothing to change")
        return
    if os.path.exists(SETTINGS):
        shutil.copy(SETTINGS, SETTINGS + ".bak-claude-update")
    settings["hooks"]["SessionStart"] = kept
    json.dump(settings, open(SETTINGS, "w"), indent=2)
    print("removed auto-briefing hook" if uninstall else f"installed auto-briefing hook: {CMD}")


if __name__ == "__main__":
    main()
