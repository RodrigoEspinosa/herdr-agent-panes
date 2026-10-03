# shellcheck shell=bash disable=SC2034
# Sourced by guard.sh, session-context.sh and herdr-run. Sets defaults, then
# sources the user's config so anything set there wins.

MODE=deny             # deny | warn | off
EXTRA_PATTERNS=()     # extra ERE patterns that count as long-running
ALLOW_PATTERNS=()     # ERE patterns that are never blocked (checked first)
LAYOUT=dock           # dock | split
DOCK_WIDE_COLS=140    # agent pane at least this wide: dock on the right, else bottom
DOCK_COLS=64          # right dock width, clamped to 28-45% of the agent pane
DOCK_BOTTOM_PERCENT=30
# Commands whose pane gets less (small) or more (large) of the dock.
SMALL_PATTERNS=(
  'docker([[:space:]]+|-)compose'
  '(^|[[:space:]/])(postgres|redis-server|mongod|mysqld|minio|mailpit|mailhog)([[:space:]]|$)'
  'supabase[[:space:]]+start'
  '(tsc|tailwindcss)[^;&|]*[[:space:]](--watch|-w)([[:space:]]|$)'
  '(cargo[[:space:]]+watch|watchexec|bacon)'
)
LARGE_PATTERNS=()
OUTPUT_LINES=40       # lines of recent output herdr-run prints

HERDR_AGENT_PANES_CONFIG="${HERDR_AGENT_PANES_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/herdr-agent-panes/config.sh}"
# shellcheck source=/dev/null
if [ -f "$HERDR_AGENT_PANES_CONFIG" ]; then . "$HERDR_AGENT_PANES_CONFIG"; fi
