#!/usr/bin/env bash
set -euo pipefail

vxl=vxl-host
veth="vxl-br0"
laddr6="$(ip --json addr show dev "${veth}" | jq -r '[.[0].addr_info[] | select((.family == "inet6") and (.local | startswith("fe")))][0].local')"
grp="ff02::1"

ip -6 link add "${vxl}" type vxlan \
        id 100 \
        dstport 4789 \
	group "${grp}" \
        dev "${veth}" \
        ttl 5

ip -6 addr add fe13:37:ffff:ffff:ffff:ffff::ffff/64 dev "${vxl}"
ip link set "${vxl}" up
bash
ip link del "${vxl}"
