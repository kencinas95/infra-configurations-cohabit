#!/usr/bin/env bash

set -ea

env_file="../../env/${THIS_ENV}/mdb.env"

if [[ ! -f "$env_file" ]]; then
  echo "[ERROR] .env file not found: $(realpath $env_file)"
  exit -1
fi

source "$env_file"

mongosh -u "$MDB_ROOT_USERNAME" -p "$MDB_ROOT_PASSWORD" --file init.js