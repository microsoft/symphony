#!/usr/bin/env bash

_set_api_version() {
  uri=$1
  paas_version=$2

  echo "$1$2"
}

check_error_log() {
  if [[ -f "$AZDO_TEMP_LOG_PATH/http.error.log" ]]; then
    echo ""
    _error "Please check $AZDO_TEMP_LOG_PATH/http.error.log for install errors"
  fi
}

verify_response() {
  local _request_uri=$1
  local _response=$2

  if [[ "$_response" == *"innerException"* ]]; then
    {
      echo "----------------------------------------------"
      echo "Inner Exception in Http Response "
      echo "_request_uri: $_request_uri"
      echo "_response: "
      echo "$_response"
    } >>"$AZDO_TEMP_LOG_PATH/http.error.log"

  fi
  if [[ "$_response" == *"Azure DevOps Services | Sign In"* ]]; then
    {
      echo "----------------------------------------------"
      echo "Azure DevOps Services | Sign In Http Response (html login screen)"
      echo "_request_uri: $_request_uri"
      echo "_response: "
      echo "$_response"
    } >>"$AZDO_TEMP_LOG_PATH/http.error.log"
  fi
  if [[ "$_response" == *"Access Denied: The Personal Access Token used has expired"* ]]; then
    {
      echo "----------------------------------------------"
      echo "Access Denied: The Personal Access Token used has expired (html screen)"
      echo "_request_uri: $_request_uri"
      echo "_response: "
      echo "$_response"
    } >>"$AZDO_TEMP_LOG_PATH/http.error.log"
  fi
}
_debug_log_patch() {
  _debug "REQ - $1"
  _debug "RES - "
  _debug_json "$2"
  _debug "PAYLOAD -"
  _debug_json "$3"
}

request_patch() {
  request_uri=${1}
  payload=${2}
  content_type=${3}
  authorization=${4}

  _response=$(curl \
    --silent \
    --location \
    --header "Content-Type: ${content_type}" \
    --header "Authorization: ${authorization}" \
    --request PATCH "${request_uri}" \
    --data-raw "${payload}" \
    --compressed)

  verify_response "$request_uri" "$_response"
  echo "$_response"
}

_debug_log_post() {
  _debug "REQ -  $1"
  _debug "RES - "
  _debug_json "$2"
  _debug "PAYLOAD -"
  _debug_json "$3"
}

request_post() {
  request_uri=${1}
  payload=${2}
  content_type=${3}
  authorization=${4}

  _response=$(curl \
    --silent \
    --location \
    --header "Content-Type: ${content_type}" \
    --header "Authorization: ${authorization}" \
    --request POST "${request_uri}" \
    --data-raw "${payload}")

  verify_response "$request_uri" "$_response"
  echo "$_response"
}

request_put() {
  request_uri=${1}
  payload=${2}
  content_type=${3}
  authorization=${4}

  _response=$(curl \
    --silent \
    --location \
    --header "Content-Type: ${content_type}" \
    --header "Authorization: ${authorization}" \
    --request PUT "${request_uri}" \
    --data-raw "${payload}")

  verify_response "$request_uri" "$_response"
  echo "$_response"
}

_debug_log_get() {
  _debug "REQ - $1"
  _debug "RES - "
  _debug_json "$2"
}

request_get() {
  request_uri=${1}
  content_type=${2}
  authorization=${3}

  local _response

  _response=$(curl \
    --silent \
    --location \
    --header "Content-Type: ${content_type}" \
    --header "Authorization: ${authorization}" \
    --request GET "${request_uri}")

  verify_response "$request_uri" "$_response"
  echo "$_response"
}

_debug_log_post_binary() {
  _debug "REQ - $1"
  _debug "RES - "
  _debug_json "$2"
  _debug "FILE_NAME -  $3"
}
