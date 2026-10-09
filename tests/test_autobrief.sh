#!/bin/bash
# Tests for autobrief.sh and install_hook.py in a throwaway HOME.
# usage: bash tests/test_autobrief.sh
REPO="$(cd "$(dirname "$0")/.." && pwd)"
export HOME="$(mktemp -d)"
trap 'rm -rf "$HOME"' EXIT
mkdir -p "$HOME/.claude" "$HOME/.local/bin" "$HOME/.local/share/claude/versions"
STATE="$HOME/.claude/.update-briefing.json"
pass=0 fail=0
check() { if [ "$2" = "$3" ]; then echo "PASS $1"; pass=$((pass+1)); else echo "FAIL $1: expected [$3] got [$2]"; fail=$((fail+1)); fi; }
install() { touch "$HOME/.local/share/claude/versions/$1"; ln -sf "$HOME/.local/share/claude/versions/$1" "$HOME/.local/bin/claude"; }
# Run the hook under a parent process named "claude" with the given args,
# the way Claude Code launches it.
hook() { (exec -a claude bash -c 'bash "$0" </dev/null' "$REPO/autobrief.sh" "$@"); }

install 2.1.10
check "first run is silent" "$(hook)" ""
check "first run records baseline" "$(cat "$STATE")" '{"last_briefed": "2.1.10"}'
check "same version is silent" "$(hook)" ""

install 2.1.12
out=$(hook)
check "update emits SessionStart context" "$(python3 -c 'import json,sys;print(json.loads(sys.argv[1])["hookSpecificOutput"]["hookEventName"])' "$out" 2>/dev/null)" "SessionStart"
check "context names the version gap" "$(echo "$out" | grep -o 'from 2.1.10 to 2.1.12')" "from 2.1.10 to 2.1.12"
check "headless -p is skipped" "$(hook -p hello)" ""
check "headless --print is skipped" "$(hook --print hello)" ""
check "state untouched until briefed" "$(cat "$STATE")" '{"last_briefed": "2.1.10"}'

python3 "$REPO/changelog.py" --mark-briefed 2.1.12 >/dev/null
check "silent after briefing" "$(hook)" ""
install 2.1.9
check "downgrade is silent" "$(hook)" ""

S="$HOME/.claude/settings.json"
echo '{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"other.sh"}]}]},"model":"x"}' > "$S"
python3 "$REPO/install_hook.py" >/dev/null
python3 "$REPO/install_hook.py" >/dev/null
count() { python3 -c 'import json,sys;d=json.load(open(sys.argv[1]));print(sum("autobrief.sh" in h["command"] for e in d["hooks"]["SessionStart"] for h in e["hooks"]))' "$S"; }
check "installer adds hook once" "$(count)" "1"
check "installer keeps other hooks" "$(python3 -c 'import json;d=json.load(open("'"$S"'"));print(len(d["hooks"]["SessionStart"]), d["model"])')" "2 x"
python3 "$REPO/install_hook.py" --uninstall >/dev/null
check "uninstall removes hook" "$(count)" "0"

echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
