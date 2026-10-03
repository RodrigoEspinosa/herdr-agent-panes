## Long-running processes in Herdr

When `HERDR_ENV=1` (you're inside a Herdr pane), never run dev servers, watchers or other long-running commands (`npm/pnpm/yarn/bun dev|start|watch`, `vite`, `next dev`, `expo start`, `docker compose up`, `--watch`, …) in your own shell, in the background, or with `&`/`nohup`. Use `herdr-run` instead:

```bash
herdr-run --wait 'Local:|ready|listening' -- npm run dev
```

- It first checks the current workspace for a pane already running that command in the same directory and reuses it (`status=running`). Otherwise it reuses an idle pane it spawned earlier, or splits a new pane without stealing focus (`status=started`).
- It prints the pane ID plus recent output. Read more later with `herdr pane read <pane> --source recent-unwrapped --lines 120`.
- `--restart` stops and restarts it (e.g. after config changes). `--cwd DIR` runs elsewhere. `--match REGEX` customizes running-instance detection. `herdr-run --list` shows tracked panes.
- Layout is handled for you: your chat stays the main pane and new panes go into one dock beside it (right column on wide screens, bottom strip otherwise). Pass `--size` to say how much the output matters: `large` for the thing you are actively working on, `normal` (default for app/dev servers), `small` for background infrastructure you rarely read (databases, `docker compose`, type-check or CSS watchers). It's guessed from the command when omitted. Don't create panes with `herdr pane split` yourself.
- If the user asks to tidy or rearrange the panes, run `herdr-run --arrange`: it moves every non-agent pane in the tab into the dock, ordered and sized by importance.
- Before starting something that binds a port, assume the user may already be running it: reuse it rather than starting a second copy on another port.
- Don't kill, close or restart panes you didn't start without asking.
- A bounded one-off (e.g. checking that a server boots) can run directly with `timeout N <cmd>`.

A PreToolUse hook (herdr-agent-panes) enforces this and will deny such commands with a pointer back here.
