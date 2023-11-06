#!/bin/bash

# Includes
source _helpers.sh

usage() {
  _information "Usage: Git helper to report diff between two git branches "
  exit 1
}

# git_diff "main" "Update_iac_terraform" "./../../IAC/Terraform/terraform" return_res_var
git_diff() {
  base_branch=$1
  new_branch=$2
  path=$3
  result=$4

  _information "Run Git diff cmd to detect layers changes"

  cmd_options="--diff-filter=d --name-only ${base_branch}..${new_branch} "

  if [[ ! -z "$3" ]]; then
    cmd_options="${cmd_options} ${path}"
  fi

  echo "git diff $cmd_options | xargs -L1 dirname | uniq"
  res=$(git diff "$cmd_options" | xargs -L1 dirname | uniq)

  SAVEIFS=${IFS}
  IFS=$'\n'

  array=($res)
  IFS=${SAVEIFS}

  len=${#array[@]}

  _information "Changes Detected in ${len} layers"
  _information "$res"

  if [[ "$4" ]]; then
    eval "$result"="'$res'"
  else
    echo "$res"
  fi
}
