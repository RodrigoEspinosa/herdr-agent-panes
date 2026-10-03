# herdr-agent-panes configuration.
#
# Copy this file to ~/.config/herdr-agent-panes/config.sh (or point
# $HERDR_AGENT_PANES_CONFIG at another path) and uncomment what you want to
# change. Every setting has a working default, so an empty config is fine.
# It is plain bash, sourced by the hook and by herdr-run.

# ---- guard ----

# What the PreToolUse hook does with a long-running command inside herdr:
#   deny  block it and tell the agent to use herdr-run (default)
#   warn  let it run, but remind the agent to use herdr-run
#   off   do nothing
# MODE=deny

# Extra commands that count as long-running, as extended regexes matched
# against the shell command (quoted strings removed first).
# EXTRA_PATTERNS=(
#   '(^|[;&|[:space:]])make[[:space:]]+serve([[:space:];&|]|$)'
#   '(^|[;&|[:space:]])tilt[[:space:]]+up([[:space:];&|]|$)'
# )

# Commands that are never blocked, even if a built-in pattern matches. Checked
# before everything else.
# ALLOW_PATTERNS=(
#   'npm[[:space:]]+run[[:space:]]+start:ci'
# )

# ---- herdr-run ----

# Where new panes go:
#   dock   one dock beside the agent pane: a column on the right when the agent
#          pane is at least DOCK_WIDE_COLS wide, else a strip along the bottom.
#          New panes stack inside the dock and never split the agent again.
#   split  plain split next to the agent (right when wide, else down)
# LAYOUT=dock
# DOCK_WIDE_COLS=140
# DOCK_COLS=64              # right dock width, clamped to 28-45% of the agent pane
# DOCK_BOTTOM_PERCENT=30

# Inside the dock, panes are ordered large, normal, small and share space 3:2:1.
# herdr-run --size overrides the guess. Assigning an array replaces the default
# list; use SMALL_PATTERNS+=(...) to extend it.
# SMALL_PATTERNS+=('(^|[[:space:]])ngrok([[:space:]]|$)')
# LARGE_PATTERNS=('storybook')

# Lines of recent pane output herdr-run prints (--lines overrides it).
# OUTPUT_LINES=40
