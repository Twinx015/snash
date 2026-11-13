#!/usr/bin/env bash
if ((BASH_VERSINFO[0] < 4)); then
    if [[ -z ${SNASH_REEXEC-} && -f ${BASH_SOURCE[0]-} ]]; then
        for _snash_bash in \
            /opt/homebrew/bin/bash /usr/local/bin/bash /opt/local/bin/bash \
            /home/linuxbrew/.linuxbrew/bin/bash /usr/pkg/bin/bash; do
            if [[ -x $_snash_bash ]]; then
                SNASH_REEXEC=1 exec "$_snash_bash" "${BASH_SOURCE[0]}" "$@"
            fi
        done
    fi
    echo "snake.sh needs bash 4 or newer (found $BASH_VERSION)." >&2
    echo "On macOS: brew install bash" >&2
    exit 1
fi

ESC=$'\e'

die() {
    printf 'snash: %s\n' "$*" >&2
    exit 1
}

[[ -n ${WIDTH-} ]] && WIDTH_FIXED=1 || WIDTH_FIXED=0
[[ -n ${HEIGHT-} ]] && HEIGHT_FIXED=1 || HEIGHT_FIXED=0

: "${WIDTH:=50}"
: "${HEIGHT:=80}"

: "${TWO_FOOD_UNTIL_SCORE:=60}"

: "${HIGH_SCORE_FILE:=${HOME:-.}/.snash}"
: "${HISTORY_FILE:=${HOME:-.}/.snash_history}"

: "${INITIAL_DELAY_MS:=120}"
: "${MIN_DELAY_MS:=50}"
: "${SPEEDUP_MS:=1}"

: "${KEY_UP:=w}"
: "${KEY_DOWN:=s}"
: "${KEY_LEFT:=a}"
: "${KEY_RIGHT:=d}"
: "${KEY_QUIT:=q}"
: "${KEY_SCORES:=h}"

KEY_UP=${KEY_UP,,}
KEY_DOWN=${KEY_DOWN,,}
KEY_LEFT=${KEY_LEFT,,}
KEY_RIGHT=${KEY_RIGHT,,}
KEY_QUIT=${KEY_QUIT,,}
KEY_SCORES=${KEY_SCORES,,}

if [[ -n ${NO_COLOR-} || ${TERM-} == dumb ]]; then
    _head='@@' _body='##' _food='()'
    BANNER_COLOR='' RESET=''
else
    RESET="${ESC}[0m"
    _head="${ESC}[1;32m@@${RESET}"
    _body="${ESC}[32m##${RESET}"
    _food="${ESC}[31m()${RESET}"
    case ${COLORTERM-} in
    truecolor | 24bit) BANNER_COLOR="${ESC}[38;2;79;124;255m" ;;
    *) BANNER_COLOR="${ESC}[1;34m" ;;
    esac
fi

: "${CELL_EMPTY:=  }"
: "${CELL_HEAD:=$_head}"
: "${CELL_BODY:=$_body}"
: "${CELL_FOOD:=$_food}"

case ${SNASH_UNICODE-auto} in
0 | no | false) UNICODE=0 ;;
auto)
    case ${LC_ALL:-${LC_CTYPE:-${LANG-}}} in
    *[Uu][Tt][Ff]-8* | *[Uu][Tt][Ff]8*) UNICODE=1 ;;
    *) UNICODE=0 ;;
    esac
    ;;
*) UNICODE=1 ;;
esac

SNAKE_X=()
SNAKE_Y=()
DIR=right
MOVED_DIR=right
BOOST=0
SCORE=0
DELAY_MS=0
FOOD_X=()
FOOD_Y=()
HLINE=""
KEY=""
STTY_SAVED=""
HAVE_CLOCK=0
NOW_MS=0
TERM_ROWS=0
TERM_COLS=0

place_food() {
    local i fx fy ok
    if ((${#SNAKE_X[@]} + ${#FOOD_X[@]} >= WIDTH * HEIGHT)); then return 1; fi
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
    if ((SCORE <= TWO_FOOD_UNTIL_SCORE)); then
        want=2
    fi
    while ((${#FOOD_X[@]} < want)); do
        place_food || break
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
    MOVED_DIR=right
    BOOST=0
    SCORE=0
    DELAY_MS=$INITIAL_DELAY_MS
    ensure_food_count
}

HIGH_SCORE=0
GAME_NUMBER=0

load_high_score() {
    local value
    HIGH_SCORE=0
    [[ -r $HIGH_SCORE_FILE ]] || return 0
    value=$(<"$HIGH_SCORE_FILE")
    value=${value//[!0-9]/}
    [[ -n $value ]] && HIGH_SCORE=$((10#$value))
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
    GAME_NUMBER=$((10#${count:-0} + 1))

    printf 'Game %d : %d [ %s ]( %s )\n' \
        "$GAME_NUMBER" "$score" "$date" "$time" >>"$HISTORY_FILE" 2>/dev/null

    if ((score > HIGH_SCORE)) || [[ ! -e $HIGH_SCORE_FILE ]]; then
        HIGH_SCORE=$score
        printf '%d\n' "$HIGH_SCORE" >"$HIGH_SCORE_FILE" 2>/dev/null
    fi
}

show_scores() {
    local line _ num score date time total=0 i start=0
    local -a rows=()

    if [[ -r $HISTORY_FILE ]]; then
        while IFS= read -r line || [[ -n $line ]]; do
            read -r _ num _ score _ date _ time _ <<<"$line" || continue
            [[ -n $num && -n $score ]] || continue
            total=$((total + 1))
            rows+=("$(printf '%-6s %-8s %-12s %s' "$num" "$score" "$date" "$time")")
        done <"$HISTORY_FILE"
    fi

    printf '\e[2J\e[H'
    printf '  HIGH SCORE: %d\n' "$HIGH_SCORE"
    printf '  GAMES PLAYED: %d\n\n' "$total"

    if ((${#rows[@]} == 0)); then
        printf '  No games recorded yet.\n'
    else
        printf '  %-6s %-8s %-12s %s\n' 'GAME' 'SCORE' 'DATE' 'TIME'
        printf '  %s\n' '------------------------------------------'
        if ((${#rows[@]} > 10)); then
            start=$((${#rows[@]} - 10))
        fi
        for ((i = start; i < ${#rows[@]}; i++)); do
            printf '  %s\n' "${rows[i]}"
        done
        if ((start > 0)); then
            printf '\n  Showing the last 10 of %d games.\n' "${#rows[@]}"
        fi
    fi

    printf '\n  Press any key to go back.'
    read_key
    printf '\e[2J\e[H'
}

open_input() {
    [[ -t 1 ]] || die "stdout is not a terminal."
    if [[ -t 0 ]]; then
        exec 3<&0
    elif { : </dev/tty; } 2>/dev/null; then
        exec 3</dev/tty
    else
        die "no terminal available for keyboard input."
    fi
}

get_term_size() {
    local out
    TERM_ROWS=0
    TERM_COLS=0
    if out=$(stty size <&3 2>/dev/null) &&
        [[ $out =~ ^([0-9]+)[[:space:]]+([0-9]+)$ ]]; then
        TERM_ROWS=${BASH_REMATCH[1]}
        TERM_COLS=${BASH_REMATCH[2]}
    elif command -v tput >/dev/null 2>&1; then
        TERM_ROWS=$(tput lines 2>/dev/null)
        TERM_COLS=$(tput cols 2>/dev/null)
        [[ $TERM_ROWS =~ ^[0-9]+$ ]] || TERM_ROWS=0
        [[ $TERM_COLS =~ ^[0-9]+$ ]] || TERM_COLS=0
    fi
}

fit_to_terminal() {
    local max_h max_w
    get_term_size
    ((TERM_ROWS > 0 && TERM_COLS > 0)) || return 0

    max_h=$((TERM_ROWS - 8))
    max_w=$(((TERM_COLS - 2) / 2))
    if ((max_h < 4 || max_w < 6)); then
        die "terminal too small (${TERM_COLS}x${TERM_ROWS}); need at least 14x12."
    fi

    if ((HEIGHT > max_h)); then
        ((HEIGHT_FIXED)) &&
            die "HEIGHT=$HEIGHT needs $((HEIGHT + 8)) terminal rows (have $TERM_ROWS)."
        HEIGHT=$max_h
    fi
    if ((WIDTH > max_w)); then
        ((WIDTH_FIXED)) &&
            die "WIDTH=$WIDTH needs $((WIDTH * 2 + 2)) terminal columns (have $TERM_COLS)."
        WIDTH=$max_w
    fi
}

term_cleanup() {
    if [[ -n $STTY_SAVED ]]; then
        stty "$STTY_SAVED" <&3 2>/dev/null
    fi
    printf '\e[?7h\e[?25h\e[%d;1H\n' $((HEIGHT + 8))
}

term_setup() {
    STTY_SAVED=$(stty -g <&3 2>/dev/null) || STTY_SAVED=""
    [[ -n $STTY_SAVED ]] && stty -echo <&3 2>/dev/null
    trap term_cleanup EXIT
    trap 'exit 0' INT TERM HUP
    printf '\e[2J\e[?25l\e[?7l'
}

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
    printf '%s to see scores\n' "${KEY_SCORES^^}"
    printf 'SPACE to restart, ENTER to quit\n'
}

show_title() {
    local line
    local -a banner

    if ((UNICODE)); then
        banner=(
            '███████╗███╗   ██╗ █████╗ ███████╗██╗  ██╗'
            '██╔════╝████╗  ██║██╔══██╗██╔════╝██║  ██║'
            '███████╗██╔██╗ ██║███████║███████╗███████║'
            '╚════██║██║╚██╗██║██╔══██║╚════██║██╔══██║'
            '███████║██║ ╚████║██║  ██║███████║██║  ██║'
            '╚══════╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝'
        )
    else
        banner=(
            ' ____  _   _    _    ____  _   _ '
            '/ ___|| \ | |  / \  / ___|| | | |'
            '\___ \|  \| | / _ \ \___ \| |_| |'
            ' ___) | |\  |/ ___ \ ___) |  _  |'
            '|____/|_| \_/_/   \_\____/|_| |_|'
        )
    fi

    printf '\e[2J\e[H'
    for line in "${banner[@]}"; do
        printf '%s%s%s\n' "$BANNER_COLOR" "$line" "$RESET"
    done
    printf '\n'
    printf '%s / arrows to move, %s to quit\n' \
        "${KEY_UP^^}${KEY_LEFT^^}${KEY_DOWN^^}${KEY_RIGHT^^}" "${KEY_QUIT^^}"
    printf 'SPACE toggles speed boost\n'
    printf '%s to see scores\n\n' "${KEY_SCORES^^}"
    printf 'press SPACE to start.'
}

detect_clock() {
    local t
    HAVE_CLOCK=0
    if [[ -n ${EPOCHREALTIME-} ]]; then
        now_ms() {
            local t=${EPOCHREALTIME/[.,]/}
            NOW_MS=$((10#$t / 1000))
        }
        HAVE_CLOCK=1
    else
        t=$(date +%s%3N 2>/dev/null)
        if [[ $t =~ ^[0-9]{13,}$ ]]; then
            now_ms() { NOW_MS=$(date +%s%3N); }
            HAVE_CLOCK=1
        fi
    fi
}

fmt_timeout() {
    printf -v TIMEOUT '%d.%03d' $(($1 / 1000)) $(($1 % 1000))
}

read_key() {
    local k ch rest n status
    KEY=""

    if [[ -n ${1-} ]]; then
        IFS= read -rsn1 -t "$1" -u 3 k
    else
        IFS= read -rsn1 -u 3 k
    fi
    status=$?
    if ((status > 128)); then return 1; fi
    if ((status != 0)); then exit 0; fi

    case $k in
    '' | $'\r')
        KEY=enter
        return 0
        ;;
    ' ')
        KEY=space
        return 0
        ;;
    $'\e')
        if ! IFS= read -rsn1 -t 0.02 -u 3 ch; then
            KEY=esc
            return 0
        fi
        rest=$ch
        if [[ $ch == '[' || $ch == O ]]; then
            n=0
            while ((n < 6)) && IFS= read -rsn1 -t 0.02 -u 3 ch; do
                rest+=$ch
                [[ $ch == [A-Za-z~] ]] && break
                ((n++))
            done
        fi
        case $rest in
        '[A' | OA) KEY=up ;;
        '[B' | OB) KEY=down ;;
        '[C' | OC) KEY=right ;;
        '[D' | OD) KEY=left ;;
        *) KEY=other ;;
        esac
        return 0
        ;;
    esac

    k=${k,,}
    case $k in
    "$KEY_UP") KEY=up ;;
    "$KEY_DOWN") KEY=down ;;
    "$KEY_LEFT") KEY=left ;;
    "$KEY_RIGHT") KEY=right ;;
    "$KEY_SCORES") KEY=scores ;;
    "$KEY_QUIT") KEY=quit ;;
    *) KEY=other ;;
    esac
    return 0
}

drain_input() {
    local junk
    while IFS= read -rsn1 -t 0.3 -u 3 junk; do :; done
}

wait_for_start() {
    while true; do
        read_key
        case $KEY in
        space)
            printf '\e[2J'
            return 0
            ;;
        scores)
            show_scores
            show_title
            ;;
        quit) exit 0 ;;
        esac
    done
}

wait_for_restart() {
    local result=$1
    while true; do
        read_key
        case $KEY in
        space) return 0 ;;
        scores)
            show_scores
            draw
            show_message "$result"
            ;;
        enter | quit) exit 0 ;;
        esac
    done
}

apply_key() {
    case $KEY in
    up) [[ $MOVED_DIR != down ]] && DIR=up ;;
    down) [[ $MOVED_DIR != up ]] && DIR=down ;;
    left) [[ $MOVED_DIR != right ]] && DIR=left ;;
    right) [[ $MOVED_DIR != left ]] && DIR=right ;;
    space) BOOST=$((1 - BOOST)) ;;
    quit) exit 0 ;;
    esac
    return 0
}

read_input() {
    local delay=$DELAY_MS deadline remaining
    if ((BOOST)); then
        delay=$((delay / 2))
        ((delay < 10)) && delay=10
    fi

    if ((HAVE_CLOCK)); then
        now_ms
        deadline=$((NOW_MS + delay))
        while true; do
            now_ms
            remaining=$((deadline - NOW_MS))
            ((remaining > 0)) || break
            fmt_timeout "$remaining"
            read_key "$TIMEOUT" || break
            apply_key
        done
    else
        fmt_timeout "$delay"
        read_key "$TIMEOUT" && apply_key
    fi
    return 0
}

game_step() {
    local nx=${SNAKE_X[0]} ny=${SNAKE_Y[0]} i limit eating=0 len=${#SNAKE_X[@]} food_index=-1

    case $DIR in
    up) ((ny--)) ;;
    down) ((ny++)) ;;
    left) ((nx--)) ;;
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

    MOVED_DIR=$DIR

    if ((eating)); then
        SNAKE_X=("$nx" "${SNAKE_X[@]}")
        SNAKE_Y=("$ny" "${SNAKE_Y[@]}")
        ((SCORE += 10))
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

validate_config() {
    local v
    for v in WIDTH HEIGHT TWO_FOOD_UNTIL_SCORE INITIAL_DELAY_MS MIN_DELAY_MS SPEEDUP_MS; do
        [[ ${!v} =~ ^[0-9]+$ ]] || die "config error: $v must be a non-negative integer (got '${!v}')."
        printf -v "$v" '%d' "$((10#${!v}))"
    done
    for v in KEY_UP KEY_DOWN KEY_LEFT KEY_RIGHT KEY_QUIT KEY_SCORES; do
        local val=${!v}
        ((${#val} == 1)) || die "config error: $v must be exactly one character."
    done
    if ((WIDTH < 6 || HEIGHT < 4)); then
        die "config error: board is too small (min WIDTH=6, HEIGHT=4)."
    fi
    fit_to_terminal
}

main() {
    local status result

    open_input
    validate_config
    detect_clock
    load_high_score
    render_init
    term_setup

    game_init
    show_title
    wait_for_start

    while true; do
        draw
        read_input
        game_step
        status=$?
        if ((status != 0)); then
            draw
            record_game "$SCORE"
            if ((status == 2)); then result="YOU WIN"; else result="GAME OVER"; fi
            show_message "$result"
            drain_input
            wait_for_restart "$result"
            game_init
        fi
    done
}

main "$@"
