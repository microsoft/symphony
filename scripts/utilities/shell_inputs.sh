#!/usr/bin/env bash

# shell helpers to read and validate input

function _select_list_no_display() {
  variable="$1"
  message="${2:-Please make a selection}"
  list=($3)
  label=$4
  input=""
  found=1
  while [ $found -ne 0 ]; do
    printf "\e[35m> %s : \e[0m" "$message"
    read -r input
    if [[ " list " =~ " ${input} " ]]; then
      PS3="$(printf '\e[0m')?> "
      printf "\n\e[35m"
      select input in "${list[@]}"; do
        re='^[0-9]+$'
        if [[ $REPLY =~ $re ]]; then
          eval "$variable=$input"
          found=0
          break
        else
          if ! [[ " ${list[*]} " =~ " ${REPLY} " ]]; then
            echo "$REPLY is not a valid selection."
          else
            eval "$variable=$REPLY"
            found=0
            break
          fi
        fi
      done
      printf "\e[0m"
    elif ! [[ " ${list[*]} " =~ " ${input} " ]]; then
      _error "$input is not a valid $label."
    else
      eval "$variable=$input"
      found=0
    fi
  done

}
function _select_list() {
  variable="$1"
  message="${2:-Please make a selection}"
  list=($3)
  is_danger=${4}
  # configure the select prompt via the PS3 variable
  PS3="$(printf '\e[0m')?> "

  if [[ "$is_danger" == "true" ]]; then
    printf "\e[31m> %s : \e[0m" "$message"
    printf "\n\e[31m"
  else
    _prompt "$message"
    printf "\n\e[35m"
  fi
  select input in "${list[@]}"; do
    re='^[0-9]+$'
    if [[ $REPLY =~ $re ]]; then
      eval "$variable=$input"
      break
    else
      if ! [[ " ${list[*]} " =~ " ${REPLY} " ]]; then
        echo "$REPLY is not a valid selection."
      else
        eval "$variable=$REPLY"
        break
      fi
    fi
  done
  printf "\e[0m"
}

function _select_yes_no() {
  variable="$1"
  message="${2:-Please make a selection}"
  is_danger=${3}

  # configure the select prompt via the PS3 variable
  PS3="$(printf '\e[0m')?> "

  if [[ "$is_danger" == "true" ]]; then
    printf "\e[31m> %s : \e[0m" "$message"
    printf "\n\e[31m"
  else
    _prompt "$message"
    printf "\n\e[35m"
  fi
  select input in yes no; do
    re='^[0-9]+$'
    if [[ $REPLY =~ $re ]]; then
      eval "$variable=$input"
      break
    else
      case $REPLY in
      yes)
        eval "$variable=yes"
        break
        ;;

      no)
        eval "$variable=no"
        break
        ;;
      *)
        _error "$REPLY is an Invalid selection, please select yes or no"
        ;;
      esac
    fi
  done
  printf "\e[0m"
}

function _prompt_input {
  input_description=${1}
  input_name=${2}
  is_danger=${3}

  echo ""
  if [[ "$is_danger" == "true" ]]; then
    printf " \e[31m> %s : \e[0m" "$input_description"
  else
    echo -n "> $input_description : "
  fi

  read $input_name
}

function _validate_inputs {
  code=0
  if [ -z "$ORCHESTRATOR" ]; then
    _error "Please specify an orchestrator "
    code=1
  fi

  if [ -z "$IACTOOL" ]; then
    _error "Please specify an iac tool "
    code=2
  fi

  echo ""
  return $code
}

function usage() {
  # me is defined in the entry point script that sources this file.

  _helpText=" Usage: $me <command> <sub command> <parameters>
  commands:
    provision  Set up the required infrastructure needed for symphony
    destroy    Remove the required infrastructure needed for symphony
    pipeline
      sub commands:
        config
          arguments:
            provider   (required)    azdo|github       specify the desired orchestrator
            iac_tool   (required)    terraform|bicep   specify the desired iac tool to configure
        example:
          symphony pipeline config azdo terraform
          symphony pipeline config github bicep

"
  _information "$_helpText" 1>&2
  exit 0
}
