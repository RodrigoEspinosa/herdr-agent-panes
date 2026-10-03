#!/usr/bin/env bash
# herdr plugin action: run `herdr-run --arrange` on the focused tab.
#
# The main pane is the tab's agent: the focused pane if it is one, else the
# first agent pane in the tab, else (no agent) the focused pane itself.
set -euo pipefail
herdr="${HERDR_BIN_PATH:-herdr}"

pane="${HERDR_PANE_ID:-}"
[ -n "$pane" ] || pane=$("$herdr" pane current | jq -r .result.pane.pane_id)
info=$("$herdr" pane get "$pane" | jq -c .result.pane)
tab=$(jq -r .tab_id <<<"$info")
ws=$(jq -r .workspace_id <<<"$info")
main=$("$herdr" pane list --workspace "$ws" | jq -r --arg t "$tab" --arg f "$pane" '
  [.result.panes[] | select(.tab_id == $t)] as $p
  | ([$p[] | select(.pane_id == $f and (.agent // "") != "")]
     + [$p[] | select((.agent // "") != "")]
     + [{pane_id: $f}])[0].pane_id')

HERDR_ENV=1 HERDR_WORKSPACE_ID="$ws" HERDR_PANE_ID="$main" \
  exec bash "$(dirname "${BASH_SOURCE[0]}")/../bin/herdr-run" --arrange
