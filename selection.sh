#!/bin/bash
#
# Create selections checkboxes in CLI
# Author: Roko C. Buljan

# PUBLIC
declare -a selection=()

# PRIVATE
declare -a _selection_items=()
declare -a _selection_active=()
declare -i _selection_tot=0
declare -i _selection_cursor=0


inArray() {
    local val
    for val in "${@:2}"; do [[ "$val" == "$1" ]] && return 0; done
    return 1
}

draw() {
    # Clear the terminal
    clear

    title="${title:-"Select the desired options:"}"
    local outNavInfo=""
    if [[ $_selection_tot -gt 0 ]]; then
        outNavInfo="Use [Arrows] to navigate, [Space] to toggle, "
    fi
    local out="$title\n($outNavInfo[Enter] to proceed)\n\n"

    local arrow="\e[33m➜\e[0m" # arrow cursor
    local ckbOn="[\e[32m■\e[0m]" # checked
    local ckbOff="[\e[31m \e[0m]" # unchecked ✕
    local -i i=0

    for (( i=0; i<$_selection_tot; i++ )); do  

        # >> ARROW
        if [[ "${i}" -eq "${_selection_cursor}" ]]; then
            out+="$arrow  "
        else
            out+="   "
        fi

        # >> CHECKBOXES
        if inArray $i "${_selection_active[@]}"; then
            out+="$ckbOn"
        else
            out+="$ckbOff"
        fi

        # >> ITEM NAME
        if [[ "${i}" -eq "${_selection_cursor}" ]]; then
            out+=" \e[33m${_selection_items[$i]}\e[0m\n"
        else
            out+=" ${_selection_items[$i]}\n"
        fi
    done

    echo -e "$out"
}

moveUp() {
    ((_selection_cursor-=1))
    if [[ $_selection_cursor -lt 0 ]]; then
        _selection_cursor=$(($_selection_tot-1))
    fi
    draw
}

moveDown() {
    ((_selection_cursor+=1))
    if [[ $_selection_cursor -ge $_selection_tot ]]; then
        _selection_cursor=0
    fi
    draw
}

toggle() {
    if inArray $_selection_cursor "${_selection_active[@]}"; then
        _selection_active=("${_selection_active[@]/$_selection_cursor}")
    else
        _selection_active+=($_selection_cursor)
    fi
    _selection_active=($(printf "%s\n" "${_selection_active[@]}")) 
    draw   
}

main() {
    while getopts "ht:" opt; do
        case $opt in
            h)
                echo "Usage: source $0 [-h] [-t title] \"a_checked:1\" \"b_unchecked:0\" \"c_unchecked\" ..."
                shift
                exit 0
                ;;
            t)
                title=$OPTARG
                shift 2
                ;;
            \?)
                echo "Invalid option: -$OPTARG" >&2
                exit 1
                ;;
            :)
                echo "Option -$OPTARG requires an argument." >&2
                exit 1
                ;;
        esac
    done

    # Get the remaining arguments after optiosn shifting
    local -a args=("$@")
    local -i i=0

    # Extract items and checked states
    for i in "${!args[@]}"; do
        arg="${args[$i]}"
        IFS=':' read -r name ckd <<<"$arg"
        # Make unchecked by default
        local checked="${ckd:-"0"}"
        # Populate items names
        _selection_items+=("$name")
        # Populate checked indexes
        [[ "$checked" -eq "1" ]] && _selection_active+=("$i")
    done
    unset IFS

    # Update total items
    _selection_tot="${#_selection_items[@]}"

    # FIRST DRAW:
    draw
}

watchKeys() {
    # WATCH KEYS
    while true; do
        read -rsN 1 # read a single character
        case "$REPLY" in
            $'\x1b') # escape sequence, could be an arrow key
                read -rsN 2 # read the next two characters
                case "$REPLY" in
                    '[A'|'[D') # up, right arrows
                        moveUp
                        ;;
                    '[B'|'[C') # down, left arrows
                        moveDown
                        ;;
                esac
                ;;
            $' ') # space
                toggle
                ;;
            $'\n') # enter/return
                break
                ;;
        esac
    done
}

output() {
    # Collect selected items by active indexes
    # Export selections array in the original order
    local -i idx
    for idx in "${!_selection_items[@]}"; do
        if inArray "$idx" "${_selection_active[@]}"; then
            selection+=("${_selection_items[$idx]}")
        fi
    done
}

# Init!
main "$@"
watchKeys
output

# Clear public variables
unset _selection_items
unset _selection_active
unset _selection_tot
unset _selection_cursor
# Notice:
# selection array is passed through!
