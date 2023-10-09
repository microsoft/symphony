#!/usr/bin/env bash

# Above check is disabled since ShellSpec passes in a special parameter with the function name

# This callback function will be invoked after core modules has been loaded.
spec_helper_configure() {
    # Available functions: import, before_each, after_each, before_all, after_all
    import 'support/custom_matcher'
}

# Resource Helper Functions
get_resource_group_by_name() {
    resourceGroupName=$1
    run_az "az group show --resource-group $resourceGroupName -o json"
}

get_storage_account_by_name() {
    storageAccountName=$1
    run_az "az storage account show --name $storageAccountName -o json"
}

get_sql_server_by_name() {
    resourceGroupName=$1
    sqlServerName=$2
    run_az "az sql server show --resource-group $resourceGroupName --name $sqlServerName -o json"
}

get_sql_database_by_name() {
    resourceGroupName=$1
    sqlServerName=$2
    sqlDatabaseName=$3
    run_az "az sql db show --resource-group $resourceGroupName --server $sqlServerName --name $sqlDatabaseName -o json"
}

# AZ CLI functions
run_az() {
    command=$1
    json=$(exec $command)
    echo "$json"
    local code=$?
    if [[ -n "$json" ]]; then
        echo "$json"
    fi
    return $code
}

# Assertions
query_equals() {
    local query="$1"
    local expected="$2"
    local json="$query_equals"
    if [[ "$#" -gt 2 ]]; then
        json="$3"
    fi
    local actual
    actual=$(echo "$json" | jq -r "$query")

    if [[ "$actual" == "$expected" ]]; then
        return 0
    else
        new_line
        error "   query: $query"
        error "expected: $expected"
        error "  actual: $actual"
        return 1
    fi
}

name_equals() {
    local expected="$1"
    local json="$name_equals"
    query_equals ".name" "$expected" "$json"
}

location_equals() {
    local expected="$1"
    local json="$location_equals"
    query_equals ".location" "$expected" "$json"
}

# LOGGER functions
error() {
    printf "\e[31mERROR: %s\n\e[0m" "$@"
}

information() {
    printf "  \e[36m%s\n\e[0m" "$@"
}

success() {
    printf "  \e[32m%s\n\e[0m" "$@"
}

clear_print_log() {
    rm -f logs/log.txt
}

new_line() {
    echo -e "\n"
}
