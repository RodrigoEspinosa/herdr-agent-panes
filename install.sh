#!/usr/bin/env bash
# Install from a git checkout: ./install.sh, or ./install.sh --uninstall.
# Same as `bin/herdr-agent-panes install|uninstall`.
cmd=install
[ "${1:-}" = --uninstall ] && cmd=uninstall
exec "$(cd "$(dirname "$0")" && pwd -P)/bin/herdr-agent-panes" "$cmd"
