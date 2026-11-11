#!/usr/bin/env bash
term_cleanup() {
  printf '\e[?25h'
  printf '\e[%d;1H\n' $((HEIGHT + 5))
}

term_setup() {
  trap term_cleanup EXIT
  trap 'exit 0' INT TERM
  printf '\e[2J\e[?25l'
}
