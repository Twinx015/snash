# Snake (Bash)

A terminal Snake game written entirely in Bash, with no dependencies beyond Bash 4+ and a terminal that supports ANSI escape sequences. The whole game lives in a single file, `snake.sh`.

## Requirements

- Bash 4.0 or newer
- Linux, macOS, or WSL on Windows
- A terminal that supports ANSI colors (the title uses 24-bit color)
- Enough space for the board: at least `2 * WIDTH + 2` columns and `HEIGHT + 6` rows (defaults: 32 x 36)

## Run

```bash
./snake.sh
```

If the script is not executable:

```bash
bash snake.sh
```

Play without cloning (single-file download):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Twinx015/snash/main/snake.sh)
```

Or pipe it straight into Bash — the script reads keys from `/dev/tty`, so the pipe does not steal your input:

```bash
curl -fsSL https://raw.githubusercontent.com/Twinx015/snash/main/snake.sh | bash
```

For a stable URL, pin a tag or commit instead of `main`. As with any remote script, prefer saving and reviewing it before running it.

macOS ships with Bash 3.2. Install a newer version and run the game with it:

```bash
brew install bash
bash snake.sh
```

## Controls

| Key | Action |
| --- | --- |
| `Space` | Start the game / restart after game over |
| `W` `A` `S` `D` or arrow keys | Move up, left, down, right |
| `S` | Show the score table (start and game-over screens) |
| `q` | Quit |
| `Enter` | Exit from the game-over screen |

During play `s` is the *down* movement key; the score table is only available on the start and game-over screens.

The snake cannot reverse directly into itself. Direction changes are applied on the next game step.

> Note: the start screen currently prints "Space to speed", but Space is only handled on the start and game-over screens. It has no effect during play.

## Gameplay

- Eat food to grow the snake and gain **10 points** per item.
- Each food eaten reduces the step delay by `SPEEDUP_MS`, making the game faster, down to `MIN_DELAY_MS`.
- While the score is at or below `TWO_FOOD_UNTIL_SCORE` (default **70**), two food items stay on the board. After that, only one remains.
- Hitting a wall or the snake's own body ends the game.
- Filling the board wins the game.

## High score and history

Every finished game (win or loss) is recorded automatically.

`~/.snash` stores the best score as a plain number:

```
50
```

`~/.snash_history` stores every finished game, one line per game:

```
Game 1 : 40 [ 2026-11-11 ]( 10:21 )
Game 2 : 50 [ 2026-11-11 ]( 10:24 )
Game 3 : 30 [ 2026-11-11 ]( 10:31 )
```

The format is `Game <number> : <score> [ <date> ]( <time> )`. Game numbers continue from the number of lines already in the history file. Quitting mid-game with `q` does not add an entry.

Press `s` on the start or game-over screen to see the most recent 10 games in a table with the game number, score, date, and time.

Both paths can be changed with the `HIGH_SCORE_FILE` and `HISTORY_FILE` variables (for example, `HIGH_SCORE_FILE=/tmp/snake.high ./snake.sh`).

## Configuration

Defaults live at the top of `snake.sh`. Every value can also be overridden through the environment:

```bash
WIDTH=20 HEIGHT=10 INITIAL_DELAY_MS=150 ./snake.sh
```

| Variable | Default | Description |
| --- | --- | --- |
| `WIDTH` | `15` | Board width in cells (minimum 6) |
| `HEIGHT` | `30` | Board height in cells (minimum 4) |
| `TWO_FOOD_UNTIL_SCORE` | `70` | Keep two foods on the board while the score is at or below this value |
| `INITIAL_DELAY_MS` | `120` | Delay between steps at the start of a game |
| `MIN_DELAY_MS` | `50` | Fastest allowed step delay |
| `SPEEDUP_MS` | `1` | Delay removed after each food eaten |
| `KEY_UP` | `w` | Move up |
| `KEY_DOWN` | `s` | Move down |
| `KEY_LEFT` | `a` | Move left |
| `KEY_RIGHT` | `d` | Move right |
| `KEY_QUIT` | `q` | Quit immediately |
| `KEY_SCORES` | `s` | Open the score table on the start and game-over screens |
| `CELL_EMPTY` | `  ` (two spaces) | Empty cell |
| `CELL_HEAD` | green `@@` | Snake head |
| `CELL_BODY` | green `##` | Snake body |
| `CELL_FOOD` | red `()` | Food |
| `HIGH_SCORE_FILE` | `$HOME/.snash` | High score file |
| `HISTORY_FILE` | `$HOME/.snash_history` | Game history file |

The snake always starts 3 cells long. `CELL_EMPTY`, `CELL_HEAD`, `CELL_BODY`, and `CELL_FOOD` must all render as the same number of terminal columns (two by default), or the grid will become misaligned.

## Project layout

```
snake.sh    The entire game: settings, state, rendering, input, scoring
README.md   Documentation
LICENSE     MIT license
```

## License

MIT — see [LICENSE](LICENSE). Copyright (c) 2026 Twinx015.

## Troubleshooting

- **The board wraps or looks broken:** the terminal is too small, or a custom `CELL_*` string is not two columns wide.
- **Colors are wrong:** use a terminal with ANSI/truecolor support and a color-capable `TERM`.
- **High score or history does not update:** make sure `$HOME` is writable and that the configured paths are valid.
