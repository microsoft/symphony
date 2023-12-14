#!/bin/env bash

# Includes
source ./_helpers.sh

azlogin "${ARM_SUBSCRIPTION_ID}" "${ARM_TENANT_ID}" "${ARM_CLIENT_ID}" "${ARM_CLIENT_SECRET}" 'AzureCloud'

# expects EVENTS_STORAGE_ACCOUNT, EVENTS_TABLE_NAME to be set

usage() {
  _information "Usage: helpers to store and query events"
  exit 1
}

query_events() {
  local pipeline_name=$1
  local event_name=$2
  local event_group_id=$3

  filter_expression="${odata_filter} PartitionKey eq '${pipeline_name}'"

  cmd="az storage entity query \
        --account-name ${EVENTS_STORAGE_ACCOUNT} \
        --table-name ${EVENTS_TABLE_NAME} \
        --filter \"\
            PartitionKey eq '${pipeline_name}' and \
            EventName eq '${event_name}' and \
            EventGroupId eq '${event_group_id}'\""

  resultJson=$(eval "${cmd}")
  exit_code=$?

  if [[ ${exit_code} != 0 ]]; then
    return ${exit_code}
  fi

  local values=$(echo "${resultJson}" | jq -r ".items")

  echo $values
}

store_event() {
  local pipeline_name=$1
  local event_name=$2
  local event_group_id=$3
  local data=$4

  # data is a set of key=value pairs, separated by spaces

  local id=$(uuidgen)

  _information "Store event ${event_name} with group id ${event_group_id} from pipeline ${pipeline_name} with id ${id}"

  local cmd="az storage entity insert \
        --entity \
            PartitionKey=${pipeline_name} \
            RowKey=$id \
            EventName=${event_name} \
            EventGroupId=${event_group_id} \
            $data \
        --table-name $EVENTS_TABLE_NAME \
        --account-name $EVENTS_STORAGE_ACCOUNT"

  _information "Executing: ${cmd}"
  eval "${cmd}"

  return $?
}
