#!/usr/bin/env bash

if ! command -v jq &> /dev/null; then
  echo "Error: 'jq' needs to be installed"
  exit 1
fi

VNNAMES=$(sudo virsh net-list | awk 'NR > 2 && $2 == "active" {print $1}')

NETWORKS_JSON=()

for VNNAME in $VNNAMES; do
    XML=$(sudo virsh net-dumpxml "$VNNAME")

    IP=$(echo "$XML" | grep -oP "<ip address='\K[^']+" | head -n 1)
    MASK=$(echo "$XML" | grep -oP "netmask='\K[^']+" | head -n 1)
    PREFIX=$(echo "$XML" | grep -oP "prefix='\K[^']+" | head -n 1)

    [ -z "$IP" ] && continue

    if [ -n "$PREFIX" ]; then
        CIDR_VAL="$PREFIX"
    elif [ -n "$MASK" ]; then
        CIDR_VAL=$(python3 -c "import socket; print(bin(int.from_bytes(socket.inet_aton('$MASK'), 'big')).count('1'))")
    else
        CIDR_VAL="24"
    fi

    NETWORK_BASE=$(python3 -c "import ipaddress; print(ipaddress.ip_network(f'$IP/$CIDR_VAL', strict=False).network_address)")

    OBJ=$(printf '{"name": "%s", "cidr": "%s/%s", "gateway": "%s"}' "$VNNAME" "$NETWORK_BASE" "$CIDR_VAL" "$IP")
    NETWORKS_JSON+=("$OBJ")
done

printf "%s\n" "${NETWORKS_JSON[@]}" | jq -s '.'
