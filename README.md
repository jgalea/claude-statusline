<div align="center">

<img src=".github/assets/header.png" alt="claude-statusline" width="760">

[![License](https://img.shields.io/badge/LICENSE-MIT-5C9E31?style=for-the-badge)](LICENSE)
[![Built by](https://img.shields.io/badge/BUILT%20BY-JEAN%20GALEA-8A2BE2?style=for-the-badge)](https://github.com/jgalea)

**A zero-dependency status line for Claude Code. One bash file, no Node, no Nerd Font.**

</div>

It reads the session JSON that Claude Code pipes to stdin and prints a single colored line: working directory, git branch, model, output style, context usage and headroom, rate limits with reset countdowns, lines changed, session cost and burn rate, and a wall clock. Everything degrades gracefully, so missing fields just drop out instead of breaking the line.

```
pa (main*) | Opus 4.8 high Explanatory | ctx:42% 118k left | 5h:73% in 1h12m | 7d:21% | +156/-23 | $1.23 $1.7/h | 21:16
```

The percentages are color-coded so you can read state at a glance instead of parsing numbers: green when there's headroom, yellow as you approach a limit, red when you're close.

## Why this and not the others

Most Claude Code status lines are npm packages that need Node 18+ and look their best with a Nerd Font installed. This one is a single shell script. Drop it in, point one setting at it, done. Nothing to install, nothing to keep updated, no fonts to chase.

If you want themes, a TUI panel, and a web configurator, the heavier projects are a better fit. If you want the numbers that matter on one line with no moving parts, this is it.

## Requirements

- Claude Code
- `jq` (`brew install jq`, or your package manager)
- `git` if you want the branch segment
- A terminal that renders ANSI colors (any modern one does)

## Install

Save the script somewhere stable and make it executable:

```bash
mkdir -p ~/.claude
curl -fsSL https://raw.githubusercontent.com/jgalea/claude-statusline/main/statusline.sh \
  -o ~/.claude/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh
```

Then point Claude Code at it in `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  }
}
```

Start a new Claude Code session and the line appears at the bottom.

## What each segment means

| Segment | Source | Notes |
|---|---|---|
| `pa (main*)` | working dir + git | `*` means uncommitted changes |
| `Opus 4.8 high Explanatory` | model, reasoning effort, output style | effort and style drop out when absent or default |
| `ctx:42% 118k left` | context window used + headroom | green below 50, yellow at 50, red at 80; `left` is tokens remaining, so you know when to `/compact` |
| `5h:73% in 1h12m` | 5-hour rate limit | countdown to reset |
| `7d:21%` | 7-day rolling limit | green below 70, yellow at 70, red at 90 |
| `+156/-23` | lines added / removed | hidden when nothing changed |
| `$1.23 $1.7/h` | session cost + burn rate | client-side estimate; rate is cost ÷ session time, shown after ~1 min |
| `21:16` | wall clock | local time |

## Customizing

It's one readable file, so edit it directly. The pieces you'll most likely touch:

- Color thresholds live in the `colorpct VALUE WARN CRIT` calls. Change `50 80` or `70 90` to taste.
- Drop a segment by deleting its block. Reorder by moving the `parts+=(...)` lines.
- Colors are plain ANSI variables at the top (`GREEN`, `YELLOW`, `RED`, `MAGENTA`, `DIM`).

## License

MIT. See [LICENSE](LICENSE).
