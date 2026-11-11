#!/usr/bin/env bash

if ((BASH_VERSINFO[0] < 4)); then
  echo "snake.sh needs bash 4 or newer (found $BASH_VERSION)." >&2
  echo "On macOS: brew install bash" >&2
  exit 1
fi

SNAKE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SNAKE_DIR/config.sh"

MODULES=(score terminal state render input logic)
for module in "${MODULES[@]}"; do
  source "$SNAKE_DIR/lib/$module.sh"
done

validate_config() {
  if ((WIDTH < 6 || HEIGHT < 4)); then
    echo "config error: board is too small (min WIDTH=6, HEIGHT=4)." >&2
    exit 1
  fi
}

msg(){
    printf "[38;2;79;124;255m███████╗███╗   ██╗ █████╗ ███████╗██╗  ██╗[0m\n"
    printf "[38;2;79;124;255m██╔════╝████╗  ██║██╔══██╗██╔════╝██║  ██║[0m\n"
    printf "[38;2;79;124;255m███████╗██╔██╗ ██║███████║███████╗███████║[0m\n"
    printf "[38;2;79;124;255m╚════██║██║╚██╗██║██╔══██║╚════██║██╔══██║[0m\n"
    printf "[38;2;79;124;255m███████║██║ ╚████║██║  ██║███████║██║  ██║[0m\n"
    printf "[38;2;79;124;255m╚══════╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝[0m\n"
    printf "\n"
      printf "${KEY_UP^^}${KEY_LEFT^^}${KEY_DOWN^^}${KEY_RIGHT^^} / arrows to move, ${KEY_QUIT} to quit\n"
      printf "Space to speed\n\n"
      printf "press SPACE to start."
}

main() {
  local status

  validate_config
  load_high_score
  render_init
  term_setup

  game_init
  msg
  wait_for_start

  while true; do
    draw
    read_input
    game_step
    status=$?
    if ((status != 0)); then
      draw
      record_game "$SCORE"
      if ((status == 2)); then show_message "YOU WIN"; else show_message "GAME OVER"; fi
      wait_for_restart
      game_init
    fi
  done
}

main "$@"
