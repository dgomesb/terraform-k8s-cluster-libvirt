#!/usr/bin/env bash

## This script is intended to work as a terraform Data Source to output disk.name and disk.path

set -e

if ! command -v jq &> /dev/null; then
  echo "Error: 'jq' needs to be installed"
  exit 1
fi

eval "$(jq -r '@sh "STORAGE_NAME=\(.storage_name) BASE_OS_NAME=\(.base_os_name)"')"

LINE=$(sudo virsh vol-list --pool "$STORAGE_NAME" 2>/dev/null | grep -w "$BASE_OS_NAME" | head -n 1 || true)

if [ -z "$LINE" ]; then
    echo "{\"name\": \"$BASE_OS_NAME\", \"path\": \"\"}" | jq '.'
else
    #NAME=$(echo "$LINE" | awk '{print $1}')
    PATH_VOL=$(echo "$LINE" | awk '{print $2}')

    echo "{\"name\": \"$BASE_OS_NAME\", \"path\": \"$PATH_VOL\"}" | jq '.'
fi
