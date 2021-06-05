#!/usr/bin/env bash
set -euo pipefail

brdname="vxl-br0"

# Set up bridge when needed
if [ -z "${IN_NS-}" ] && ! ip link show "${brdname}" &>/dev/null; then
	ip link add name "${brdname}" type bridge
	ip addr add 10.145.0.254/24 dev "${brdname}"
	ip link set "${brdname}" up
fi

if [ -z "${IN_NS-}" ]; then
	IN_NS="vxl-$(uuidgen | tr -d '-')"
	ip netns add "${IN_NS}"
	ip netns exec "${IN_NS}" ip link set dev lo up

	# Create veth pair and move it to ${IN_NS}
	pairname="veth${IN_NS: -2}"
	peername="veth-${IN_NS: -4}"
	ip=$(( $(bridge --json link show "${brdname}" | jq -r 'length') + 1 ))

	ip link add name "${pairname}" type veth peer name "${peername}"
	ip link set dev "${peername}" up

	ip link set dev "${pairname}" netns "${IN_NS}"
	#ip netns exec "${IN_NS}" ip addr add 10.145.0."${ip}"/24 dev "${pairname}"
	ip netns exec "${IN_NS}" ip link set dev "${pairname}" up

	# Attach host side veth to the br
	ip link set dev "${peername}" master "${brdname}"

	exec ip netns exec "${IN_NS}" env IN_NS="${IN_NS}" NUM="${ip}" "${0}" "${@}"
fi

nsn="${IN_NS}"
nsp="$(readlink /proc/$$/ns/net)"
echo "in ns: ${nsn} ($nsp)"
echo "num: ${NUM}"

main_eth="$(ip --json link list | jq -r '[.[] | select(.link_type == "ether") | .ifname][0]')"
laddr6="$(ip --json addr show dev "${main_eth}" | jq -r '[.[0].addr_info[] | select((.family == "inet6") and (.local | startswith("fe")))][0].local')"
grp="ff02::1"
vxl="vxl0"

ip -6 link add "${vxl}" type vxlan \
	id 100 \
	dstport 4789 \
	local "${laddr6}" \
	group "${grp}" \
	dev "${main_eth}" \
	ttl 5

ip -6 addr add fe13:37:ffff:ffff:ffff:ffff::"${NUM}"/64 dev "${vxl}"
ip link set "${vxl}" up

bash
