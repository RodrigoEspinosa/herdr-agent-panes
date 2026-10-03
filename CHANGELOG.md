# Changelog

## 0.2.0

- Dock layout: the agent's pane stays the main pane and herdr-run panes go into
  one dock beside it (right column when the agent pane is wide, bottom strip
  otherwise) instead of splitting the agent pane again.
- `--size small|normal|large` orders the dock and shares its space 1:2:3. It is
  guessed from the command (databases, docker compose and watchers are small).
- `herdr-run --arrange` tidies the current tab into that layout.
- Config: `LAYOUT`, `DOCK_WIDE_COLS`, `DOCK_COLS`, `DOCK_BOTTOM_PERCENT`,
  `SMALL_PATTERNS`, `LARGE_PATTERNS` (replace `SPLIT_DIRECTION` and
  `SPLIT_WIDE_COLS`).

## 0.1.0

- `herdr-run`, the PreToolUse guard and the agent instructions, packaged as a
  Claude Code plugin.
- `herdr-agent-panes install|uninstall|status` wires it into Claude Code and
  Codex. Hooks run from a stable root, so upgrades apply without reinstalling.
- Config file for guard mode, extra/allowed patterns and pane placement.
