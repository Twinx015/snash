#!/usr/bin/env bash
wait_for_start() {
  local key
  while true; do
    IFS= read -rsn1 key || exit 0
    key=${key,,}
    [[ $key == ' ' ]] && return 0
    [[ $key == "$KEY_QUIT" ]] && exit 0
  done
}

wait_for_restart() {
  local key
  while true; do
    IFS= read -rsn1 key || exit 0
    key=${key,,}
    if [[ $key == ' ' ]]; then
      return 0
    elif [[ -z $key || $key == "$KEY_QUIT" ]]; then
      exit 0
    fi
  done
}

read_input() {
  local key rest timeout
  printf -v timeout '%d.%03d' $((DELAY_MS / 1000)) $((DELAY_MS % 1000))

  IFS= read -rsn1 -t "$timeout" key || return 0
  if [[ $key == $'\e' ]]; then
    IFS= read -rsn2 -t 0.01 rest
    case $rest in
      '[A') key=$KEY_UP ;;
      '[B') key=$KEY_DOWN ;;
      '[C') key=$KEY_RIGHT ;;
      '[D') key=$KEY_LEFT ;;
      *) key="" ;;
    esac
  fi

  key=${key,,}
  case $key in
    "$KEY_UP")    [[ $DIR != down ]] && DIR=up ;;
    "$KEY_DOWN")  [[ $DIR != up ]] && DIR=down ;;
    "$KEY_LEFT")  [[ $DIR != right ]] && DIR=left ;;
    "$KEY_RIGHT") [[ $DIR != left ]] && DIR=right ;;
    "$KEY_QUIT")  exit 0 ;;
  esac
  return 0
}
