---
name: claude-update
description: Update Claude Code and brief the user on what the new version changed for their setup, meaning fixes to problems they have hit, new capabilities worth using, and anything that could break their scripts, hooks or automations. Use whenever the user says "claude update", "update claude", asks what's new in Claude Code, or what an update changed.
---

# Claude Code update + briefing

"Successfully updated to X" tells the user nothing. This skill turns the update
into a short briefing filtered to what they actually run.

## Steps

1. **Record the starting version.** `command claude --version` (use `command`
   in case `claude` is a shell wrapper) and `readlink ~/.local/bin/claude`.
2. **Update.** `command claude update`, then confirm with `command claude --version`.
   Exit 0 is not proof; the version string is. If already current, still run
   step 3 with `--since-briefed`, since they may have updated in a plain shell.
3. **Pull the changelog for the gap.**
   `python3 ~/.claude/skills/claude-update/changelog.py <old> <new>`
   (or `--since-briefed <new>`). It reads the official anthropics/claude-code
   CHANGELOG.md. If the entry isn't there yet, say the changelog lags the
   release; never summarize from memory.
4. **Filter to their setup.** Read every entry and keep only what touches
   something they run: hooks, MCP servers/connectors, headless `claude -p`
   scripts, scheduled jobs, settings, plugins, skills, subagents, model routing.
   Drop IDE, Windows and enterprise-admin items they don't use.
5. **Check "could break" items for real.** For any changed or removed flag,
   setting, env var or output format, grep where it would live (their
   `~/.claude/settings.json`, hooks, scripts, launch agents, project folders)
   before calling it safe. Report what you searched. An empty grep means
   "not in these paths", not "unused anywhere".
6. **Mark it briefed.** `python3 ~/.claude/skills/claude-update/changelog.py --mark-briefed <new>`

## The briefing

Answer first: one line on whether anything matters. Then up to three groups,
each item one or two plain sentences on what it means for them:

- **Fixes something we've hit**: tie it to the incident if known; say when it is an inference.
- **New and worth using**: say where it would help and offer to wire it in.
- **Could break something**: what changed, where you grepped, what you found.

Close with housekeeping, one line each: restart open sessions, and how many old
binaries in `~/.local/share/claude/versions/` could be deleted (offer, never
delete unasked; keep the one the symlink targets).

Skip empty groups. No changelog dump, no filler.
