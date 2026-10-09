# claude-update

A Claude Code skill that updates Claude Code and briefs you on what the new version changed for your setup.

## Install

```
git clone https://github.com/eudotong1/claude-update ~/.claude/skills/claude-update
```

Then type `claude update` in a Claude Code session.

## Automatic briefings (optional)

Claude Code updates itself in the background, so you may never type `claude update`.
To get the briefing anyway, register the SessionStart hook:

```
python3 ~/.claude/skills/claude-update/install_hook.py
```

When a session starts on a newer version than the last one you were briefed on,
Claude opens its first reply with the briefing, then answers your message. Each
version is briefed once. Headless runs (`claude -p` / `--print`) are skipped, so
scripts and scheduled jobs are never interrupted. The first session after
installing only records your current version; briefings start with the next update.

Remove it with `python3 ~/.claude/skills/claude-update/install_hook.py --uninstall`.
The installer backs up `settings.json` to `settings.json.bak-claude-update` before changing it.

## Tests

```
bash tests/test_autobrief.sh
```
