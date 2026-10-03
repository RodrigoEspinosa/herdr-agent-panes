#!/usr/bin/env bash
# SessionStart hook: inside Herdr, add the herdr-run guidance to the agent's
# context. Outside Herdr it prints nothing, so other sessions pay no tokens.
[ "${HERDR_ENV:-}" = 1 ] || exit 0
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=scripts/config.sh
. "$root/scripts/config.sh"
[ "$MODE" = off ] && exit 0

cat "$root/instructions.md"
# shellcheck disable=SC2016  # backticks are markdown
command -v herdr-run >/dev/null 2>&1 \
  || printf '\n`herdr-run` is not on PATH; call it as `%s`.\n' "$root/bin/herdr-run"
exit 0
