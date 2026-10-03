#!/usr/bin/env bash
# Claude Code entry point: hook.sh <guard|session-context>.
#
# Claude runs plugin hooks from a cached copy that only changes on
# `claude plugin update`. Run the scripts from the installed root instead (a
# checkout or Homebrew's opt prefix), so a git pull or brew upgrade applies
# immediately. Falls back to the cached copy when the CLI is not on PATH.
[ "${HERDR_ENV:-}" = 1 ] || exit 0
root=$(herdr-agent-panes root 2>/dev/null) && [ -f "$root/scripts/$1.sh" ] \
  || root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
exec bash "$root/scripts/$1.sh"
