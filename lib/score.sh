#!/usr/bin/env bash

HIGH_SCORE=0
GAME_NUMBER=0

load_high_score() {
  local value
  HIGH_SCORE=0
  [[ -r $HIGH_SCORE_FILE ]] || return 0
  value=$(<"$HIGH_SCORE_FILE")
  value=${value//[!0-9]/}
  [[ -n $value ]] && HIGH_SCORE=$value
  return 0
}

record_game() {
  local score=$1 stamp date time count

  stamp=$(date '+%Y-%m-%d %H:%M')
  date=${stamp% *}
  time=${stamp#* }

  count=0
  if [[ -r $HISTORY_FILE ]]; then
    count=$(wc -l <"$HISTORY_FILE" 2>/dev/null)
    count=${count//[!0-9]/}
  fi
  GAME_NUMBER=$((count + 1))

  printf 'Game %d : %d [ %s ]( %s )\n' \
    "$GAME_NUMBER" "$score" "$date" "$time" >>"$HISTORY_FILE" 2>/dev/null

  if ((score > HIGH_SCORE)) || [[ ! -e $HIGH_SCORE_FILE ]]; then
    HIGH_SCORE=$score
    printf '%d\n' "$HIGH_SCORE" >"$HIGH_SCORE_FILE" 2>/dev/null
  fi
}
