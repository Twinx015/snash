#!/usr/bin/env bash

HLINE=""

render_init() {
  local i
  HLINE="+"
  for ((i = 0; i < WIDTH * 2; i++)); do HLINE+="="; done
  HLINE+="+"
}

draw() {
  local -a grid=()
  local i x y out

  for ((i = 0; i < WIDTH * HEIGHT; i++)); do grid[i]="$CELL_EMPTY"; done

  for ((i = 0; i < ${#FOOD_X[@]}; i++)); do
    grid[(FOOD_Y[i] - 1) * WIDTH + FOOD_X[i] - 1]="$CELL_FOOD"
  done
  for ((i = ${#SNAKE_X[@]} - 1; i >= 1; i--)); do
    grid[(SNAKE_Y[i] - 1) * WIDTH + SNAKE_X[i] - 1]="$CELL_BODY"
  done
  grid[(SNAKE_Y[0] - 1) * WIDTH + SNAKE_X[0] - 1]="$CELL_HEAD"

  out=$'\e[H'"$HLINE"$'\n'
  for ((y = 0; y < HEIGHT; y++)); do
    out+="|"
    for ((x = 0; x < WIDTH; x++)); do
      out+="${grid[y * WIDTH + x]}"
    done
    out+="|"$'\n'
  done
  out+="$HLINE"$'\n'
  out+="Score: $SCORE"$'\e[K\n'
  out+=$'\e[J'

  printf '%s' "$out"
}

show_message() {
  local msg=$1
  printf '\e[%d;%dH\e[1;41m  %s  \e[0m' $((HEIGHT / 2 + 2)) $((WIDTH - ${#msg} / 2)) "$msg"
  printf '\e[%d;1H' $((HEIGHT + 4))
  printf 'Final score: %d\n' "$SCORE"
  printf 'High score: %d\n' "$HIGH_SCORE"
  printf 'SPACE to restart, ENTER to quit\n'
}
