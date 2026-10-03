# shellcheck shell=bash disable=SC2034,SC2154  # read fields kept for clarity; state_dir is herdr-run's
# Dock layout for herdr-run, sourced after config.sh. Bash 3.2 compatible.
#
# The agent's pane stays the main pane. Panes herdr-run tracks in the same tab
# form one dock beside it: a column on the right when the agent pane is at least
# DOCK_WIDE_COLS wide, else a strip along the bottom. New panes stack inside the
# dock and never split the agent pane again. Inside the dock, panes are ordered
# by size class (large, normal, small) and share space by weight (3:2:1).
#
# Panes are always added by splitting the last dock pane, so the dock is a
# right-leaning chain of splits where pane k is the first child of split k.
# Resizing pane k toward the stack direction therefore moves exactly split k.

size_weight() { case "$1" in small) echo 1 ;; large) echo 3 ;; *) echo 2 ;; esac; }

# auto_size <command> -> small | normal | large
auto_size() {
  local re
  for re in ${LARGE_PATTERNS[@]+"${LARGE_PATTERNS[@]}"}; do
    grep -qE -- "$re" <<<"$1" && { echo large; return; }
  done
  for re in ${SMALL_PATTERNS[@]+"${SMALL_PATTERNS[@]}"}; do
    grep -qE -- "$re" <<<"$1" && { echo small; return; }
  done
  echo normal
}

tab_layout() { herdr pane layout --pane "$1" | jq -c '.result.layout'; }
# rect <layout> <pane> -> "x y width height"
rect() { jq -r --arg p "$2" '.panes[] | select(.pane_id == $p) | .rect | "\(.x) \(.y) \(.width) \(.height)"' <<<"$1"; }
tracked_size() { jq -r '.size // "normal"' "$state_dir/${1//:/_}.json" 2>/dev/null || echo normal; }

# dock_panes <layout> -> tracked panes in that tab, top-to-bottom / left-to-right.
dock_panes() {
  local f p
  for f in "$state_dir"/*; do
    [ -e "$f" ] || continue
    p=$(jq -r .pane "$f")
    jq -r --arg p "$p" '.panes[] | select(.pane_id == $p) | "\(.rect.y) \(.rect.x) \(.pane_id)"' <<<"$1"
  done | sort -n -k1,1 -k2,2 | awk '{print $3}'
}

# dock_side <layout> <main> <first dock pane> -> right | down
dock_side() {
  local mx my mw mh dx dy dw dh
  read -r mx my mw mh <<<"$(rect "$1" "$2")"
  read -r dx dy dw dh <<<"$(rect "$1" "$3")"
  if [ "$dx" -ge $((mx + mw)) ]; then echo right; else echo down; fi
}

# dock_split <main width> -> "side ratio" for a new dock next to the main pane.
dock_split() {
  if [ "$1" -ge "$DOCK_WIDE_COLS" ]; then
    awk -v c="$DOCK_COLS" -v w="$1" 'BEGIN { f = c / w; if (f < .28) f = .28; if (f > .45) f = .45; printf "right %.3f\n", 1 - f }'
  else
    awk -v p="$DOCK_BOTTOM_PERCENT" 'BEGIN { printf "down %.3f\n", 1 - p / 100 }'
  fi
}

# balance <main> <side> <pane...>: size dock panes by weight along the stack.
balance() {
  local main=$1 side=$2; shift 2
  local grow=down shrink=up field=4 n=$# k j try lay total wsum len cur step
  [ "$side" = down ] && { grow=right; shrink=left; field=3; }
  local panes=("$@")
  # Split k divides panes k..n-1; its ratio is pane k's share of their length.
  # `herdr pane resize` moves the nearest divider on the --direction side of the
  # pane, by --amount (sign ignored), and may cap a big move. Split k is below
  # pane k and above pane k+1: grow pane k by pushing its edge down, shrink it
  # by pulling pane k+1's edge up. Measure and correct a few times.
  for ((k = 0; k < n - 1; k++)); do
    for try in 1 2 3; do
      lay=$(tab_layout "$main")
      total=0 wsum=0
      for ((j = k; j < n; j++)); do
        len=$(rect "$lay" "${panes[j]}" | cut -d' ' -f"$field")
        total=$((total + ${len:-0}))
        wsum=$((wsum + $(size_weight "$(tracked_size "${panes[j]}")")))
      done
      [ "$total" -gt 0 ] || return 0
      cur=$(rect "$lay" "${panes[k]}" | cut -d' ' -f"$field")
      # Done when within one cell of the target.
      step=$(awk -v c="${cur:-0}" -v t="$total" -v w="$(size_weight "$(tracked_size "${panes[k]}")")" -v s="$wsum" \
        -v g="$grow" -v r="$shrink" \
        'BEGIN { d = w / s - c / t; if (d * t >= 1) printf "%s %.3f", g, d; else if (d * t <= -1) printf "%s %.3f", r, -d }')
      [ -n "$step" ] || break
      if [ "${step% *}" = "$grow" ]; then
        herdr pane resize --pane "${panes[k]}" --direction "$grow" --amount "${step#* }" >/dev/null
      else
        herdr pane resize --pane "${panes[k + 1]}" --direction "$shrink" --amount "${step#* }" >/dev/null
      fi
    done
  done
}

# by_weight <pane...> -> the panes ordered large, normal, small (stable).
by_weight() {
  local p i=0
  for p in "$@"; do
    i=$((i + 1))
    echo "$((4 - $(size_weight "$(tracked_size "$p")"))) $i $p"
  done | sort -n -k1,1 -k2,2 | awk '{print $3}'
}

# Move a pane next to a target in the same tab. herdr ignores a move within the
# pane's own tab, so park it in a temporary tab first (which closes once empty).
move_next_to() { # pane tab target direction ratio
  herdr pane move "$1" --new-tab --label herdr-run --no-focus >/dev/null
  herdr pane move "$1" --tab "$2" --target-pane "$3" --split "$4" --ratio "$5" --no-focus >/dev/null
}

# redock <main> <pane...>: rebuild the dock from scratch in weight order.
redock() {
  local main=$1; shift
  [ $# -gt 0 ] || return 0
  local tab p prev side ratio mx my mw mh stack ordered
  tab=$(herdr pane get "$main" | jq -r .result.pane.tab_id)
  # Park every dock pane first, so the main pane's own size decides the side.
  for p in "$@"; do herdr pane move "$p" --new-tab --label herdr-run --no-focus >/dev/null; done
  read -r mx my mw mh <<<"$(rect "$(tab_layout "$main")" "$main")"
  read -r side ratio <<<"$(dock_split "$mw")"
  stack=down; [ "$side" = down ] && stack=right
  ordered=$(by_weight "$@")
  prev=""
  for p in $ordered; do
    if [ -z "$prev" ]; then
      herdr pane move "$p" --tab "$tab" --target-pane "$main" --split "$side" --ratio "$ratio" --no-focus >/dev/null
    else
      herdr pane move "$p" --tab "$tab" --target-pane "$prev" --split "$stack" --ratio 0.5 --no-focus >/dev/null
    fi
    prev=$p
  done
  # shellcheck disable=SC2086  # pane ids have no spaces
  balance "$main" "$side" $ordered
}

# spawn_docked <main> <cwd> -> new pane id, already placed and balanced.
spawn_docked() {
  local main=$1 dir=$2 lay dock first last side ratio mx my mw mh
  lay=$(tab_layout "$main")
  dock=$(dock_panes "$lay")
  if [ -z "$dock" ]; then
    read -r mx my mw mh <<<"$(rect "$lay" "$main")"
    read -r side ratio <<<"$(dock_split "$mw")"
    herdr pane split --pane "$main" --direction "$side" --ratio "$ratio" --cwd "$dir" --no-focus \
      | jq -r .result.pane.pane_id
    return
  fi
  first=$(head -1 <<<"$dock"); last=$(tail -1 <<<"$dock")
  side=$(dock_side "$lay" "$main" "$first")
  local stack=down; [ "$side" = down ] && stack=right
  herdr pane split --pane "$last" --direction "$stack" --ratio 0.5 --cwd "$dir" --no-focus \
    | jq -r .result.pane.pane_id
}

# settle_dock <main>: after a pane joined, fix order (by redocking) and sizes.
settle_dock() {
  local main=$1 lay dock side
  lay=$(tab_layout "$main")
  dock=$(dock_panes "$lay")
  [ -n "$dock" ] || return 0
  # shellcheck disable=SC2086
  if [ "$(by_weight $dock)" != "$dock" ]; then
    # shellcheck disable=SC2086
    redock "$main" $dock
  else
    side=$(dock_side "$lay" "$main" "$(head -1 <<<"$dock")")
    # shellcheck disable=SC2086
    balance "$main" "$side" $dock
  fi
}
