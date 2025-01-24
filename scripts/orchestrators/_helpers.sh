#!/bin/bash
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
source "$SCRIPT_DIR"/../utilities/shell_logger.sh

load_dotenv() {
  local dotenv_file_path="${1:-".env"}"

  if [[ -f "${dotenv_file_path}" ]]; then
    _information "Loading .env file: ${dotenv_file_path}"
    set -o allexport
    source "${dotenv_file_path}"
    set +o allexport
  fi
}
