#!/usr/bin/env bash

_set_api_version(){
    uri=$1
    paas_version=$23
    
    echo "$1$2"
}

verify_response() {
    local _request_uri=$1 
    local _response=$2
    local _token=$3

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
    request_uri=$1
    payload=$2

    _token=$(echo -n ":${AZDO_PAT}" | base64)

    _response=$(curl \
        --silent \
        --location \
        --header 'Content-Type: application/json; charset=utf-8' \
        --header "Authorization: Basic ${_token}" \
        --request PATCH ${request_uri} \
        --data-raw "${payload}" \
        --compressed)

    verify_response "$request_uri" "$_response" "$_token"
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

    _token=$(echo -n ":${AZDO_PAT}" | base64)

    _response=$(curl \
        --silent \
        --location \
        --header 'Content-Type: application/json; charset=utf-8' \
        --header "Authorization: Basic ${_token}" \
        --request POST ${request_uri} \
        --data-raw "${payload}")

    verify_response "$request_uri" "$_response" "$_token"
    echo $_response 
}

request_put(){
    request_uri=${1}
    payload=${2}

    _token=$(echo -n ":${AZDO_PAT}" | base64)

    _response=$(curl \
        --silent \
        --location \
        --header 'Content-Type: application/json; charset=utf-8' \
        --header "Authorization: Basic ${_token}" \
        --request PUT ${request_uri} \
        --data-raw "${payload}")

    verify_response "$request_uri" "$_response" "$_token"
    echo $_response 
}

_debug_log_get() {
    _debug "REQ -" $1
    _debug "RES - "
    _debug_json "$2"
}

request_get(){
    request_uri=${1}

    local _response

    _token=$(echo -n ":${AZDO_PAT}" | base64)

    _response=$(curl \
        --silent \
        --location \
        --header 'Content-Type: application/json; charset=utf-8' \
        --header "Authorization: Basic ${_token}" \
        --request GET ${request_uri} )

    verify_response "$request_uri" "$_response" "$_token"
    echo $_response 
}

_debug_log_post_binary() {
    _debug "REQ - "$1
    _debug "RES - "
    _debug_json "$2"
    _debug "FILE_NAME - " $3
}

request_post_binary(){
    request_uri=${1}
    _sec_env_filename=${2}

    _token=$(echo -n ":${AZDO_PAT}" | base64)

    _response=$(curl \
        --silent \
        --location \
        --header 'Content-Type: application/octet-stream' \
        --header "Authorization: Basic ${_token}" \
        --request POST ${request_uri} \
        --data-binary "@./${_sec_env_filename}" \
        --compressed)

    verify_response "$request_uri" "$_response" "$_token"
    echo $_response 
}
