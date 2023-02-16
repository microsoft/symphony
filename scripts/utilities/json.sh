#!/usr/bin/env bash

ensure_json_file_exists(){
    local file=$1
    if [ ! -f "$file" ]; then
        echo "{}" > "$file"
    fi
}

get_json_value(){
    local file=$1
    local key=$2
    ensure_json_file_exists "$file"
    < "$file" jq -r ".$key"
}

set_json_value(){
    local file=$1
    local key=$2
    local value=$3
    ensure_json_file_exists "$file"
   
    updated_json=$(< $file jq --arg value "$value" --arg key "$key" '.[$key] = $value')
    echo -n "$updated_json" > "$file" 
}