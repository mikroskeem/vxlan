#!/usr/bin/env bash
set -euo pipefail

vxl=vxl-host
veth=$(ip --json link list | jq -r '[.[] | select((.link_type == "ether") and (.link_netnsid != null)) | .ifname][0]')

ip link add "${vxl}" type vxlan \
        id 100 \
        dstport 4789 \
        local 10.145.0.254 \
        remote 10.145.0.1 \
        dev "${veth}" \
        ttl 5

ip addr add 10.20.1.2/24 dev "${vxl}"
ip link set "${vxl}" up
bash
ip link del "${vxl}"
