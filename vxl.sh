#!/usr/bin/env bash
set -euo pipefail

vxl=vxl-client
veth="${1}"
grp="ff02::1"
laddr="$(ip --json addr show dev "${veth}" | jq -r '[.[0].addr_info[] | select(.family == "inet6" and (.local | startswith("fe")))][0].local')"

ip -6 link add "${vxl}" type vxlan \
        id 100 \
	local "${laddr}" \
        dstport 4789 \
	group "${grp}" \
        dev "${veth}" \
        ttl 5

ip addr add 10.20.1.200/24 dev "${vxl}"
ip link set "${vxl}" up
