#!/usr/bin/env bash
# PreToolUse hook for Claude Code and Codex: inside Herdr, refuse to run dev
# servers / watchers through the agent's shell tool and point the agent at
# `herdr-run`, which reuses an existing pane or spawns a new one.
#
# Bypass for bounded runs: prefix with `timeout N` (e.g. a quick smoke test).
# Configure via ~/.config/herdr-agent-panes/config.sh (see config.example.sh).
[ "${HERDR_ENV:-}" = 1 ] || exit 0
command -v jq >/dev/null || exit 0
# shellcheck source=scripts/config.sh
. "$(dirname "${BASH_SOURCE[0]}")/config.sh"
[ "$MODE" = off ] && exit 0

input=$(cat)
cmd=$(jq -r '.tool_input.command // .tool_input.cmd // empty
  | if type == "array" then join(" ") else . end' <<<"$input" 2>/dev/null)
[ -n "$cmd" ] || exit 0
full="$cmd"
# Ignore quoted strings (grep patterns, echo, commit messages, …).
cmd=$(sed -E "s/'[^']*'//g; s/\"[^\"]*\"//g" <<<"$cmd")

# Already going through Herdr, explicitly time-boxed, or allowed by config.
grep -qE '(^|[;&|[:space:]])(herdr|herdr-run)([[:space:]]|$)' <<<"$cmd" && exit 0
grep -qE '(^|[;&|[:space:]])g?timeout[[:space:]]+[0-9]' <<<"$cmd" && exit 0
for re in ${ALLOW_PATTERNS[@]+"${ALLOW_PATTERNS[@]}"}; do
  grep -qE -- "$re" <<<"$full" && exit 0
done

B='(^|[;&|(`[:space:]])'   # start of a command word
E='([[:space:];&|)`]|$)'   # end of a command word
patterns=(
  "${B}(npm|pnpm|yarn|bun)([[:space:]]+run)?[[:space:]]+(dev|start|serve|watch|preview|storybook)(:[[:alnum:]_-]+)?${E}"
  "${B}(vite|next[[:space:]]+(dev|start)|nuxt[[:space:]]+dev|astro[[:space:]]+dev|remix[[:space:]]+dev|svelte-kit[[:space:]]+dev)${E}"
  "${B}(expo[[:space:]]+start|react-native[[:space:]]+start|nodemon|wrangler[[:space:]]+dev|vercel[[:space:]]+dev|netlify[[:space:]]+dev|convex[[:space:]]+dev|supabase[[:space:]]+start)${E}"
  "${B}(storybook[[:space:]]+dev|hugo[[:space:]]+server|jekyll[[:space:]]+serve|rails[[:space:]]+(s|server)|flask[[:space:]]+run|uvicorn|gunicorn|php[[:space:]]+artisan[[:space:]]+serve)${E}"
  "${B}python3?[[:space:]]+-m[[:space:]]+http\.server${E}"
  "${B}(cargo[[:space:]]+watch|bacon|watchexec)${E}"
  "[[:space:]]--watch(All)?${E}"
  ${EXTRA_PATTERNS[@]+"${EXTRA_PATTERNS[@]}"}
)
hit=""
for re in "${patterns[@]}"; do
  if grep -qE -- "$re" <<<"$cmd"; then hit=1; break; fi
done
# docker compose up, unless detached
if [ -z "$hit" ] && grep -qE "${B}docker([[:space:]]+|-)compose([[:space:]][^;&|]*)?[[:space:]]up${E}" <<<"$cmd" \
   && ! grep -qE '[[:space:]](-d|--detach)([[:space:]]|$)' <<<"$cmd"; then
  hit=1
fi
[ -n "$hit" ] || exit 0

suggest="herdr-run [--wait '<ready regex>'] -- $full"
if [[ "$full" =~ ^[[:space:]]*cd[[:space:]]+([^;&|]+[^;&|[:space:]])[[:space:]]*\&\&[[:space:]]*(.*)$ ]]; then
  rest="${BASH_REMATCH[2]%%&}"
  suggest="herdr-run --cwd ${BASH_REMATCH[1]} [--wait '<ready regex>'] -- ${rest%"${rest##*[![:space:]]}"}"
fi
reason="This looks like a long-running process (dev server/watcher). In Herdr, don't run it in your own shell or in the background. Use: $suggest
It reuses the pane if this is already running in the workspace, otherwise opens a new pane without stealing focus. Read logs later with: herdr pane read <pane> --source recent-unwrapped --lines 120. (For a bounded smoke test, prefix with \`timeout N\`.)"

if [ "$MODE" = warn ]; then
  jq -n --arg r "$reason" '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $r}}'
else
  jq -n --arg r "$reason" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
fi
