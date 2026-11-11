#!/usr/bin/env bash
: "${WIDTH:=80}"
: "${HEIGHT:=40}"

: "${INITIAL_LENGTH:=3}"

: "${TWO_FOOD_UNTIL_SCORE:=50}"

: "${HIGH_SCORE_FILE:=$HOME/.snash}"
: "${HISTORY_FILE:=$HOME/.snash_history}"

: "${INITIAL_DELAY_MS:=120}"
: "${MIN_DELAY_MS:=50}"
: "${SPEEDUP_MS:=4}"

# : "${POINTS_PER_FOOD:=100}"

: "${KEY_UP:=w}"
: "${KEY_DOWN:=s}"
: "${KEY_LEFT:=a}"
: "${KEY_RIGHT:=d}"
: "${KEY_QUIT:=q}"

: "${CELL_EMPTY:=  }"
: "${CELL_HEAD:=$'\e[1;32m[]\e[0m'}"
: "${CELL_BODY:=$'\e[32m==\e[0m'}"
: "${CELL_FOOD:=$'\e[31m<>\e[0m'}"
