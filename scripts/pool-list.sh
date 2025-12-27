#!/usr/bin/env bash

if ! command -v jq &> /dev/null; then
  echo "Error: 'jq' needs to be installed"
  exit 1
fi

POOLNAMES=$(sudo virsh pool-list | awk 'NR > 2 && $2 == "active" {print $1}')

POOLS_JSON=()

for POOLNAME in $POOLNAMES; do
  XML=$(sudo virsh pool-dumpxml "$POOLNAME")

  POOL_PATH=$(echo "$XML" | grep -oP "<path>\K[^<]+")
  POOL_TYPE=$(echo "$XML" | grep -oP "type='\K[^']+")
  [ -z "$POOL_PATH" ] && continue

  OBJ=$(printf '{"name": "%s", "path": "%s", "type": "%s"}' "$POOLNAME" "$POOL_PATH" "$POOL_TYPE")
  POOLS_JSON+=("$OBJ")
done

printf "%s\n" "${POOLS_JSON[@]}" | jq -s '.'
