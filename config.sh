#!/usr/bin/env bash
: "${WIDTH:=80}"
: "${HEIGHT:=40}"

: "${INITIAL_LENGTH:=9}"

: "${HIGH_SCORE_FILE:=$HOME/.snash}"
: "${HISTORY_FILE:=$HOME/.snash_history}"

: "${INITIAL_DELAY_MS:=120}"
: "${MIN_DELAY_MS:=50}"
: "${SPEEDUP_MS:=1}"

: "${KEY_UP:=w}"
: "${KEY_DOWN:=s}"
: "${KEY_LEFT:=a}"
: "${KEY_RIGHT:=d}"
: "${KEY_QUIT:=q}"

: "${CELL_EMPTY:=  }"
: "${CELL_HEAD:=$'\e[1;32m@@\e[0m'}" # keep sam   e no.
: "${CELL_BODY:=$'\e[32m##\e[0m'}"  # of char in
: "${CELL_FOOD:=$'\e[31m()\e[0m'}"  # all these three feilds