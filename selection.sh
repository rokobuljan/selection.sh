#!/bin/bash
#
# Create selections checkboxes in CLI
# https://github.com/rokobuljan/selection.sh
# Author: Roko C. Buljan

set -euo pipefail

# PUBLIC
declare -a selection=()

# PRIVATE
declare -a _selection_items=()
declare -a _selection_active=()
declare -i _selection_tot=0
declare -i _selection_cursor=0
_isMultiple=false
_isOutputIndex=false

usage() {
    echo -e "Usage:
    source $0 [-m -a] [-i] [-t title] \"a_checked:1\" \"b_unchecked:0\" \"c_unchecked\" ...
Options:
    -m Multiple (checkboxes)
    -c Inverse checked default logic
    -i Output index instead of names
    -t Title 
    -h Help
Examples:
    source $0 Yes No \"Maybe tomorrow\"
    source $0 -t \"Select one:\" \"Yes\" \"No\" \"Maybe\"  # Returns name 
    source $0 -i -t \"Select one:\" \"Yes\" \"No\" \"Maybe\"  # Returns index
    source $0 -m -t \"Select multiple:\" \"Load:1\" \"Configure:0\" \"Reboot\"  # Returns names
    source $0 -i -m -t \"Select multiple:\" \"Load:1\" \"Configure:0\" \"Reboot\"  # Returns indexes
"
    exit 0
}

inArray() {
    local val
    for val in "${@:2}"; do [[ "$val" == "$1" ]] && return 0; done
    return 1
}

draw() {
    # Clear the terminal
    clear

    if [[ "$_isMultiple" == true ]]; then
        _selection_title="${_selection_title:-"Select the desired options:"}"
    else
        _selection_title="${_selection_title:-"Select an option:"}"
    fi

    local outNavInfo="Use "
    if [[ "$_selection_tot" -gt 0 ]]; then
        outNavInfo+="[Arrows] to navigate, "
    fi

    if [[ "$_isMultiple" == true ]]; then
        outNavInfo+="[Space] to toggle, "
    fi

    local out="$_selection_title\n($outNavInfo[Enter] to proceed)\n\n"

    local arrow="\e[32m>\e[0m" # arrow cursor
    local ckbOn="[\e[32m■\e[0m]" # checked
    local ckbOff="[\e[31m \e[0m]" # unchecked ✕
    local -i i=0

    for (( i=0; i<$_selection_tot; i++ )); do  

        # ARROW
        if [[ "${i}" -eq "${_selection_cursor}" ]]; then
            out+="$arrow "
        else
            out+="  "
        fi

        # CHECKBOXES
        if [[ "$_isMultiple" == true ]]; then
            if inArray "$i" "${_selection_active[@]}"; then
                out+="$ckbOn"
            else
                out+="$ckbOff"
            fi
        fi

        # ITEM NAME
        if [[ "${i}" -eq "${_selection_cursor}" ]]; then
            out+=" \e[32m${_selection_items[$i]}\e[0m\n"
        else
            out+=" ${_selection_items[$i]}\n"
        fi
    done

    echo -e "$out"
}

moveUp() {
    _selection_cursor=$((_selection_cursor - 1))
    if [[ "$_selection_cursor" -lt 0 ]]; then
        _selection_cursor=$((_selection_tot-1))
    fi
    draw
}

moveDown() {
    _selection_cursor=$((_selection_cursor + 1))
    if [[ "$_selection_cursor" -ge "$_selection_tot" ]]; then
        _selection_cursor=0
    fi
    draw
}

toggle() {
    if [[ "$_isMultiple" == true ]]; then
        if inArray "$_selection_cursor" "${_selection_active[@]}"; then
            # Remove item index from array
            local i=0
            for i in "${!_selection_active[@]}"; do
                if [[ "${_selection_active[i]}" == "$_selection_cursor" ]]; then
                    unset "_selection_active[i]"
                fi
            done
        else
            # Insert selected item index
            _selection_active+=($_selection_cursor)
        fi
        draw
    fi 
}

main() {
    local _isDefaultChecked=false
    while getopts ":hmcit:" opt; do
        case "$opt" in
            h)
                usage 
                ;;
            m)
                _isMultiple=true
                ;;
            c)
                _isDefaultChecked=true
                ;;
            i)
                _isOutputIndex=true
                ;;
            t)
                _selection_title="$OPTARG"
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

    shift $((OPTIND-1))

    # Get the remaining arguments after optiosn shifting
    local -a args=("$@")
    local -i i=0

    # Extract items and checked states
    for i in "${!args[@]}"; do
        arg="${args[$i]}"
        IFS=':' read -r name ckd <<<"$arg"

        # Make unchecked by default, or otherwise
        local ckdDefault="0"
        if [[ "$_isDefaultChecked" == true ]]; then
            ckdDefault="1"
        fi

        local checked="${ckd:-$ckdDefault}"
        # Populate items names
        _selection_items+=("$name")
        # Populate checked indexes
        [[ "$checked" -eq "1" ]] && _selection_active+=("$i")
    done

    # Update total items
    _selection_tot="${#_selection_items[@]}"

    # FIRST DRAW:
    draw

    unset IFS
    unset OPTIND
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
                [[ "$_isMultiple" == true ]] && toggle || { clear; break; }
                ;;
            $'\n') # enter/return
                clear
                break
                ;;
        esac
    done
}

output() {
    # Collect selected items by active indexes
    # Export selections array in the original order
    if [[ "$_isMultiple" == true ]]; then
        local -i idx
        for idx in "${!_selection_items[@]}"; do
            if inArray "$idx" "${_selection_active[@]}"; then
                if [[ "$_isOutputIndex" == true ]]; then
                    selection+=("$idx")
                else
                    selection+=("${_selection_items[$idx]}")
                fi
            fi
        done
    else
        if [[ "$_isOutputIndex" == true ]]; then
            selection="$_selection_cursor"
        else
            selection="${_selection_items[$_selection_cursor]}"
        fi
    fi
}

# Init!
main "$@"
watchKeys
output

# Clear private variables
unset _selection_title
unset _selection_items
unset _selection_active
unset _selection_tot
unset _selection_cursor
unset _isMultiple
unset _isOutputIndex
# Notice:
# selection array is passed through!
