#!/usr/bin/env bash
game_step() {
  local nx=${SNAKE_X[0]} ny=${SNAKE_Y[0]} i limit eating=0 len=${#SNAKE_X[@]} food_index=-1

  case $DIR in
    up)    ((ny--)) ;;
    down)  ((ny++)) ;;
    left)  ((nx--)) ;;
    right) ((nx++)) ;;
  esac

  if ((nx < 1 || nx > WIDTH || ny < 1 || ny > HEIGHT)); then return 1; fi

  for ((i = 0; i < ${#FOOD_X[@]}; i++)); do
    if ((nx == FOOD_X[i] && ny == FOOD_Y[i])); then
      eating=1
      food_index=$i
      break
    fi
  done

  limit=$len
  ((eating)) || ((limit--))
  for ((i = 0; i < limit; i++)); do
    if ((SNAKE_X[i] == nx && SNAKE_Y[i] == ny)); then return 1; fi
  done

  if ((eating)); then
    SNAKE_X=("$nx" "${SNAKE_X[@]}")
    SNAKE_Y=("$ny" "${SNAKE_Y[@]}")
    ((SCORE += "10"))
    ((DELAY_MS > MIN_DELAY_MS)) && ((DELAY_MS -= SPEEDUP_MS))
    if ((len + 1 >= WIDTH * HEIGHT)); then return 2; fi
    remove_food "$food_index"
    ensure_food_count
  else
    SNAKE_X=("$nx" "${SNAKE_X[@]:0:len-1}")
    SNAKE_Y=("$ny" "${SNAKE_Y[@]:0:len-1}")
  fi
  return 0
}
