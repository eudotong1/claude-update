#!/bin/bash
# SessionStart hook: if Claude Code has updated since the last briefing,
# tell the session to deliver the claude-update briefing first.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE="$HOME/.claude/.update-briefing.json"

# Headless runs (claude -p / --print) never get briefed.
p=$PPID
for _ in 1 2 3; do
  args=$(ps -o args= -p "$p" 2>/dev/null) || break
  first=${args%% *}
  if [ "${first##*/}" = claude ]; then
    case " $args " in *" -p "*|*" --print "*) exit 0 ;; esac
  fi
  p=$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' ')
  [ -z "$p" ] && break
done

cur=$(basename "$(readlink "$HOME/.local/bin/claude" 2>/dev/null)")
[[ "$cur" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || cur=$("$HOME/.local/bin/claude" --version 2>/dev/null | awk '{print $1}')
[[ "$cur" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || cur=$(claude --version 2>/dev/null | awk '{print $1}')  # npm installs
[[ "$cur" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || exit 0

last=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["last_briefed"])' "$STATE" 2>/dev/null)
if [ -z "$last" ]; then
  # First run: baseline at the current version, brief from the next update on.
  python3 "$DIR/changelog.py" --mark-briefed "$cur" >/dev/null
  exit 0
fi

newer=$(python3 -c 'import sys;v=lambda s:tuple(map(int,s.split(".")));print(v(sys.argv[1])>v(sys.argv[2]))' "$cur" "$last" 2>/dev/null)
[ "$newer" = "True" ] || exit 0

msg="Claude Code updated from $last to $cur since the last update briefing. Before anything else in your first reply, use the claude-update skill to brief the user on this update: skip steps 1-2 (it is already installed), run 'python3 $DIR/changelog.py --since-briefed $cur', then filter, check, brief, and mark it briefed. Keep it short, then handle the user's message."
python3 -c 'import json,sys;print(json.dumps({"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":sys.argv[1]}}))' "$msg"
