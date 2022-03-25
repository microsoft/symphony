_debug_json() {
    if [ ${DEBUG_FLAG} == true ]; then
        echo "${@}" | jq
    fi
}

_debug() {
    # Only print debug lines if debugging is turned on.
    if [ ${DEBUG_FLAG} == true ]; then
        _color="\e[35m" # magenta
        echo -e "${_color}##[debug] $@\n\e[0m" 2>&1
    fi
}

_error() {
    _color="\e[31m" # red
    echo -e "${_color}##[error] $@\n\e[0m" 2>&1
}

_warning() {
    _color="\e[33m" # yellow
    echo -e "${_color}##[warning] $@\n\e[0m" 2>&1
}

_information() {
    _color="\e[36m" # cyan
    echo -e "${_color}##[command] $@\n\e[0m" 2>&1
}

_success() {
    _color="\e[32m" # green
    echo -e "${_color}##[command] $@\n\e[0m" 2>&1
}