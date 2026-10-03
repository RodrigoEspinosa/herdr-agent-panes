# herdr-agent-panes

Keep coding agents' dev servers and watchers in visible [herdr](https://herdr.dev)
panes instead of hidden background shells.

Left alone, an agent starts `npm run dev` in its own shell tool or in the
background. You can't see the output, it dies with the agent's shell, and the
next session starts a second copy on another port. Inside herdr, this plugin
sends that work to `herdr-run`, which:

- reuses a pane in the workspace that is already running the command in the same
  directory (`status=running`),
- else reuses an idle pane it spawned earlier for that command,
- else splits a new pane next to the agent without stealing focus
  (`status=started`),

and prints the pane ID plus recent output so the agent can read logs later
with `herdr pane read`.

New panes don't pile up wherever there's room. The agent's chat stays the main
pane and everything herdr-run starts goes into one dock beside it:

```
wide agent pane (≥140 cols)          narrow agent pane
┌──────────────────┬─────────┐       ┌────────────────────────────┐
│                  │ app dev │       │                            │
│                  │ (large) │       │        agent chat          │
│    agent chat    ├─────────┤       │                            │
│                  │  api    │       ├──────────┬───────┬─────────┤
│                  ├─────────┤       │ app dev  │  api  │ db      │
│                  │ db      │       └──────────┴───────┴─────────┘
└──────────────────┴─────────┘
```

Panes are ordered and sized by `--size` (`large` 3, `normal` 2, `small` 1), so
a database or `docker compose` log doesn't take as much room as the server
you're working on. `herdr-run --arrange` tidies an existing tab into this
layout, adopting panes you opened yourself.

Outside herdr (`HERDR_ENV` unset) everything here is a no-op.

## What's in it

| Piece | What it does |
| --- | --- |
| `bin/herdr-run` | Run a command in a reused or new pane. `herdr-run --help` lists options. |
| `scripts/layout.sh` | The dock layout used by `herdr-run`. |
| `scripts/guard.sh` | PreToolUse hook. Denies dev servers, watchers and `docker compose up` (without `-d`) run through the agent's shell, and suggests the matching `herdr-run` command. Commands prefixed with `timeout N` pass. |
| `bin/herdr-agent-panes` | `install`, `uninstall`, `status`. Wires everything into Claude Code and Codex. |
| `scripts/session-context.sh` | SessionStart hook (Claude Code). Adds `instructions.md` to the agent's context, only inside herdr. |
| `instructions.md` | The guidance agents get. Codex gets it as a marked block in `~/.codex/AGENTS.md`. |

## Install

Requires `bash`, [`jq`](https://jqlang.org) and herdr.

```bash
brew install rodrigoespinosa/tap/herdr-agent-panes
herdr-agent-panes install
```

`herdr-agent-panes install` is idempotent. It:

- adds the plugin to Claude Code (as a local marketplace),
- adds the guard to `~/.codex/hooks.json` and syncs `instructions.md` into
  `~/.codex/AGENTS.md`, if `~/.codex` exists.

Restart agent sessions afterwards. `herdr-agent-panes status` shows what is
wired up.

### Updating

```bash
brew upgrade herdr-agent-panes
```

Every hook runs scripts from Homebrew's version-independent `opt` path, so the
guard, the Claude instructions and `herdr-run` update with brew. Only the Codex
`AGENTS.md` block is a copy: run `herdr-agent-panes install` again when a
release changes `instructions.md`.

### Removing

```bash
herdr-agent-panes uninstall
brew uninstall herdr-agent-panes
```

To pause instead, set `MODE=off` in the config (below) or run
`claude plugin disable herdr-agent-panes`.

### From a checkout

```bash
git clone https://github.com/RodrigoEspinosa/herdr-agent-panes
herdr-agent-panes/install.sh              # or: install.sh --uninstall
```

This also symlinks `herdr-run` and `herdr-agent-panes` into `~/.local/bin`
(`BIN_DIR=...` to change). `git pull` updates the hooks in place.

## Keybinding

`herdr-agent-panes install` also links the repo as a herdr plugin with one
action, `herdr-agent-panes.arrange`, which tidies the focused tab. Bind it in
`~/.config/herdr/config.toml`, then run `herdr server reload-config`:

```toml
[[keys.command]]
key = "cmd+shift+a"
type = "plugin_action"
command = "herdr-agent-panes.arrange"
description = "arrange panes around the agent"
```

## Configure

Copy `config.example.sh` to `~/.config/herdr-agent-panes/config.sh` and
uncomment what you want. Both the hook and `herdr-run` read it on every call,
so changes apply immediately.

- `MODE`: `deny` (default), `warn` (let it run with a reminder) or `off`
- `EXTRA_PATTERNS` / `ALLOW_PATTERNS`: add commands to block, or exempt some
- `LAYOUT` (`dock` or `split`), `DOCK_WIDE_COLS`, `DOCK_COLS`,
  `DOCK_BOTTOM_PERCENT`: where the dock goes and how big it is
- `SMALL_PATTERNS` / `LARGE_PATTERNS`: which commands get less or more room
- `OUTPUT_LINES`: how much output `herdr-run` prints

## Development

```bash
shellcheck -x -P SCRIPTDIR/.. bin/* scripts/*.sh install.sh
claude plugin validate .
```

## License

MIT
