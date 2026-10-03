# shellcheck shell=bash disable=SC2034
# Sourced by guard.sh, session-context.sh and herdr-run. Sets defaults, then
# sources the user's config so anything set there wins.

MODE=deny             # deny | warn | off
EXTRA_PATTERNS=()     # extra ERE patterns that count as long-running
ALLOW_PATTERNS=()     # ERE patterns that are never blocked (checked first)
SPLIT_DIRECTION=auto  # auto | right | down
SPLIT_WIDE_COLS=160   # auto: split right when the agent pane is at least this wide
OUTPUT_LINES=40       # lines of recent output herdr-run prints

HERDR_AGENT_PANES_CONFIG="${HERDR_AGENT_PANES_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/herdr-agent-panes/config.sh}"
# shellcheck source=/dev/null
if [ -f "$HERDR_AGENT_PANES_CONFIG" ]; then . "$HERDR_AGENT_PANES_CONFIG"; fi
