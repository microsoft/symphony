# Logger Functions with colors for Bash Shell

_error() {
    printf "\e[31mERROR: $@\n\e[0m"
}

_debug() {
    #Only print debug lines if debugging is turned on.
    if [ "$DEBUG_FLAG" == true ]; then
        msg="$@"
        LIGHT_CYAN='\033[0;35m'
        NC='\033[0m'
        printf "DEBUG: ${NC} %s ${NC}\n" "${msg}"
    fi
}

_debug_json() {
    if [ "$DEBUG_FLAG" == true ]; then
        echo $1 | jq
    fi
}

_information() {
    printf "\e[36m$@\n\e[0m"
}

_success() {
    printf "\e[32m$@\n\e[0m"
}
