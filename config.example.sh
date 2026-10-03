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

# Where herdr-run opens a new pane next to the agent:
#   auto   right when the agent pane is at least SPLIT_WIDE_COLS wide, else down
#   right  always to the right
#   down   always below
# SPLIT_DIRECTION=auto
# SPLIT_WIDE_COLS=160

# Lines of recent pane output herdr-run prints (--lines overrides it).
# OUTPUT_LINES=40
