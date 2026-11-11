#!/usr/bin/env bash
SNAKE_X=()
SNAKE_Y=()
DIR=right
SCORE=0
DELAY_MS=0
FOOD_X=()
FOOD_Y=()

place_food() {
  local i fx fy ok
  while true; do
    fx=$((RANDOM % WIDTH + 1))
    fy=$((RANDOM % HEIGHT + 1))
    ok=1
    for ((i = 0; i < ${#SNAKE_X[@]}; i++)); do
      if ((SNAKE_X[i] == fx && SNAKE_Y[i] == fy)); then
        ok=0
        break
      fi
    done
    if ((ok)); then
      for ((i = 0; i < ${#FOOD_X[@]}; i++)); do
        if ((FOOD_X[i] == fx && FOOD_Y[i] == fy)); then
          ok=0
          break
        fi
      done
    fi
    ((ok)) && break
  done
  FOOD_X+=("$fx")
  FOOD_Y+=("$fy")
}

place_food() {
  local i fx fy ok
  while true; do
    fx=$((RANDOM % WIDTH + 1))
    fy=$((RANDOM % HEIGHT + 1))
    ok=1
    for ((i = 0; i < ${#SNAKE_X[@]}; i++)); do
      if ((SNAKE_X[i] == fx && SNAKE_Y[i] == fy)); then
        ok=0
        break
      fi
    done
    if ((ok)); then
      for ((i = 0; i < ${#FOOD_X[@]}; i++)); do
        if ((FOOD_X[i] == fx && FOOD_Y[i] == fy)); then
          ok=0
          break
        fi
      done
    fi
    ((ok)) && break
  done
  FOOD_X+=("$fx")
  FOOD_Y+=("$fy")
}

remove_food() {
  local index=$1 i
  local -a new_x=() new_y=()
  for ((i = 0; i < ${#FOOD_X[@]}; i++)); do
    ((i == index)) && continue
    new_x+=("${FOOD_X[i]}")
    new_y+=("${FOOD_Y[i]}")
  done
  FOOD_X=("${new_x[@]}")
  FOOD_Y=("${new_y[@]}")
}

ensure_food_count() {
  local want=1 n
  if ((SCORE <= "70")); then
    want=2
  fi
  while ((${#FOOD_X[@]} < want)); do
    place_food
  done
  while ((${#FOOD_X[@]} > want)); do
    n=${#FOOD_X[@]}
    FOOD_X=("${FOOD_X[@]:0:n-1}")
    FOOD_Y=("${FOOD_Y[@]:0:n-1}")
  done
}

game_init() {
  local i cx=$((WIDTH / 2)) cy=$((HEIGHT / 2))
  SNAKE_X=()
  SNAKE_Y=()
  for ((i = 0; i < 3; i++)); do
    SNAKE_X+=("$((cx - i))")
    SNAKE_Y+=("$cy")
  done
  FOOD_X=()
  FOOD_Y=()
  DIR=right
  SCORE=0
  DELAY_MS=$INITIAL_DELAY_MS
  ensure_food_count
}
