#!/usr/bin/env bash
set -euo pipefail

if [ -z "${IN_NS-}" ]; then
	IN_NS="vxl-$(uuidgen | tr -d '-')"
	ip netns add "${IN_NS}"
	ip netns exec "${IN_NS}" ip link set dev lo up

	# Create veth pair and move it to ${IN_NS}
	pairname="veth${IN_NS: -2}"
	peername="veth-${IN_NS: -4}"

	ip link add name "${pairname}" type veth peer name "${peername}"
	ip addr add 10.145.0.254/24 dev "${pairname}"
	ip link set dev "${pairname}" up

	ip link set dev "${peername}" netns "${IN_NS}"
	ip netns exec "${IN_NS}" ip addr add 10.145.0.1/24 dev "${peername}"
	ip netns exec "${IN_NS}" ip link set dev "${peername}" up

	exec ip netns exec "${IN_NS}" env IN_NS="${IN_NS}" "${0}" "${@}"
fi

nsn="${IN_NS}"
nsp="$(readlink /proc/$$/ns/net)"
echo "in ns: ${nsn} ($nsp)"

main_eth="$(ip --json link list | jq -r '[.[] | select(.link_type == "ether") | .ifname][0]')"

vxl="vxl0"
ip link add "${vxl}" type vxlan \
	id 100 \
	dstport 4789 \
	local 10.145.0.1 \
	remote 10.145.0.254 \
	dev "${main_eth}" \
	ttl 5

ip addr add 10.20.1.1/24 dev "${vxl}"
ip link set "${vxl}" up

bash
