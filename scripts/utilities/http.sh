#!/usr/bin/env bash

_set_api_version(){
    uri=$1
    paas_version=$23
    
    echo "$1$2"
}

check_error_log() {
  if [[ -f "$SCRIPT_DIR/temp/http.error.log" ]]; then
    echo ""
    _error "Please check $SCRIPT_DIR/temp/http.error.log for install errors"
  fi
}

verify_response() {
    local _request_uri=$1 
    local _response=$2

    if [[ "$_response" == *"innerException"* ]]; then
        echo "----------------------------------------------" >> $SCRIPT_DIR/temp/http.error.log
        echo "Inner Exception in Http Response " >> $SCRIPT_DIR/temp/http.error.log    
        echo "_request_uri: $_request_uri" >> $SCRIPT_DIR/temp/http.error.log    
        echo "_response: " >> $SCRIPT_DIR/temp/http.error.log    
        echo $_response >> $SCRIPT_DIR/temp/http.error.log    
    fi
    if [[ "$_response" == *"Azure DevOps Services | Sign In"* ]]; then
        echo "----------------------------------------------" >> $SCRIPT_DIR/temp/http.error.log
        echo "Azure DevOps Services | Sign In Http Response (html login screen)" >> $SCRIPT_DIR/temp/http.error.log        
        echo "_request_uri: $_request_uri" >> $SCRIPT_DIR/temp/http.error.log    
        echo "_response: " >> $SCRIPT_DIR/temp/http.error.log    
        echo $_response >> $SCRIPT_DIR/temp/http.error.log    
    fi
    if [[ "$_response" == *"Access Denied: The Personal Access Token used has expired"* ]]; then
        echo "----------------------------------------------" >> $SCRIPT_DIR/temp/http.error.log
        echo "Access Denied: The Personal Access Token used has expired (html screen)" >> $SCRIPT_DIR/temp/http.error.log        
        echo "_request_uri: $_request_uri" >> $SCRIPT_DIR/temp/http.error.log    
        echo "_response: " >> $SCRIPT_DIR/temp/http.error.log    
        echo $_response >> $SCRIPT_DIR/temp/http.error.log    
    fi    
}
_debug_log_patch() {
    _debug "REQ - "$1
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
        --request PATCH ${request_uri} \
        --data-raw "${payload}" \
        --compressed)

    verify_response "$request_uri" "$_response"
    echo $_response 
}

_debug_log_post() {
    _debug "REQ - " $1
    _debug "RES - "
    _debug_json "$2"
    _debug "PAYLOAD -"
    _debug_json "$3"
}

request_post(){
    request_uri=${1}
    payload=${2}
    content_type=${3}
    authorization=${4}

    _response=$(curl \
        --silent \
        --location \
        --header "Content-Type: ${content_type}" \
        --header "Authorization: ${authorization}" \
        --request POST ${request_uri} \
        --data-raw "${payload}")

    verify_response "$request_uri" "$_response"
    echo $_response 
}

request_put(){
    request_uri=${1}
    payload=${2}
    content_type=${3}
    authorization=${4}

    _response=$(curl \
        --silent \
        --location \
        --header "Content-Type: ${content_type}" \
        --header "Authorization: ${authorization}" \
        --request PUT ${request_uri} \
        --data-raw "${payload}")

    verify_response "$request_uri" "$_response"
    echo $_response 
}

_debug_log_get() {
    _debug "REQ -" $1
    _debug "RES - "
    _debug_json "$2"
}

request_get(){
    request_uri=${1}
    content_type=${2}
    authorization=${3}

    local _response

    _response=$(curl \
        --silent \
        --location \
        --header "Content-Type: ${content_type}" \
        --header "Authorization: ${authorization}" \
        --request GET ${request_uri} )

    verify_response "$request_uri" "$_response"
    echo $_response 
}

_debug_log_post_binary() {
    _debug "REQ - "$1
    _debug "RES - "
    _debug_json "$2"
    _debug "FILE_NAME - " $3
}
