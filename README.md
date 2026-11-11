# Snake (Bash)

A terminal Snake game written entirely in Bash, with no dependencies beyond Bash 4+ and a terminal that supports ANSI escape sequences.

## Requirements

- Bash 4.0 or newer
- Linux, macOS, or WSL on Windows
- A terminal that supports ANSI colors (the title uses 24-bit color)
- Enough space for the board: at least `2 * WIDTH + 2` columns and `HEIGHT + 6` rows (defaults: 162 x 46)

## Run

```bash
./snake.sh
```

If the script is not executable:

```bash
bash snake.sh
```

macOS ships with Bash 3.2. Install a newer version and run the game with it:

```bash
brew install bash
bash snake.sh
```

## Controls

| Key                           | Action                                   |
| ----------------------------- | ---------------------------------------- |
| `Space`                       | Start the game / restart after game over |
| `W` `A` `S` `D` or arrow keys | Move up, left, down, right               |
| `q`                           | Quit                                     |
| `Enter`                       | Exit from the game-over screen           |

The snake cannot reverse directly into itself. Direction changes are applied on the next game step.

> Note: the start screen currently prints "Space to speed", but Space is only handled on the start and game-over screens. It has no effect during play.

## Gameplay

- Eat food to grow the snake and gain **10 points** per item.
- Each food eaten reduces the step delay by `SPEEDUP_MS`, making the game faster, down to `MIN_DELAY_MS`.
- While the score is **70 or less**, two food items stay on the board. After that, only one remains. The threshold is hardcoded in `ensure_food_count()` in `lib/state.sh`.
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

Both paths can be changed with the `HIGH_SCORE_FILE` and `HISTORY_FILE` variables (for example, `HIGH_SCORE_FILE=/tmp/snake.high ./snake.sh`).

## Configuration

Defaults live in `config.sh`. Every value can also be overridden through the environment:

```bash
WIDTH=40 HEIGHT=20 INITIAL_DELAY_MS=150 ./snake.sh
```

| Variable           | Default                | Description                                |
| ------------------ | ---------------------- | ------------------------------------------ |
| `WIDTH`            | `80`                   | Board width in cells (minimum 6)           |
| `HEIGHT`           | `40`                   | Board height in cells (minimum 4)          |
| `INITIAL_DELAY_MS` | `120`                  | Delay between steps at the start of a game |
| `MIN_DELAY_MS`     | `50`                   | Fastest allowed step delay                 |
| `SPEEDUP_MS`       | `1`                    | Delay removed after each food eaten        |
| `KEY_UP`           | `w`                    | Move up                                    |
| `KEY_DOWN`         | `s`                    | Move down                                  |
| `KEY_LEFT`         | `a`                    | Move left                                  |
| `KEY_RIGHT`        | `d`                    | Move right                                 |
| `KEY_QUIT`         | `q`                    | Quit immediately                           |
| `CELL_EMPTY`       | `  ` (two spaces)      | Empty cell                                 |
| `CELL_HEAD`        | green `@@`             | Snake head                                 |
| `CELL_BODY`        | green `##`             | Snake body                                 |
| `CELL_FOOD`        | red `()`               | Food                                       |
| `HIGH_SCORE_FILE`  | `$HOME/.snash`         | High score file                            |
| `HISTORY_FILE`     | `$HOME/.snash_history` | Game history file                          |

`CELL_EMPTY`, `CELL_HEAD`, `CELL_BODY`, and `CELL_FOOD` must all render as the same number of terminal columns (two by default), or the grid will become misaligned.

## Troubleshooting

- **The board wraps or looks broken:** the terminal is too small, or a custom `CELL_*` string is not two columns wide.
- **Colors are wrong:** use a terminal with ANSI/truecolor support and a color-capable `TERM`.
- **High score or history does not update:** make sure `$HOME` is writable and that the configured paths are valid.
